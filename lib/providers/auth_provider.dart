import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/building_selection_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/building_context_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  List<BuildingSelection> _availableBuildings = [];

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get currentUserId => _currentUserId;
  List<BuildingSelection> get availableBuildings => _availableBuildings;

  AuthProvider() {
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() async {
    _user = StorageService.getUser();
    _currentUserId = _user?.id;

    // Charger le contexte de bâtiment sauvegardé
    await BuildingContextService().loadBuildingContext();

    // Mettre à jour le contexte avec le bâtiment de l'utilisateur
    if (_user?.buildingId != null) {
      BuildingContextService().setBuildingContext(_user!.buildingId!);
    }

    if (_user != null) {
      _connectWebSocket();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(email, password);

      if (response['otpRequired'] == true) {
        _setLoading(false);
        return true; // OTP required, proceed to OTP screen
      }

      // Direct login success (shouldn't happen with current API)
      await _handleLoginSuccess(response);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyLoginOtp(String email, String otpCode) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.verifyLogin(email, otpCode);
      await _handleLoginSuccess(response);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(userData);
      _setLoading(false);
      return response['otpRequired'] == true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyRegistrationOtp(String email, String otpCode) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.verifyRegistration(email, otpCode);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> response) async {
    // Vérifier si l'utilisateur doit sélectionner un bâtiment
    if (response['message'] == 'BUILDING_SELECTION_REQUIRED') {
      // Sauvegarder le token temporaire pour permettre l'accès aux endpoints de sélection
      final token = response['token'];
      if (token != null) {
        await StorageService.saveToken(token);
      }

      // Créer un utilisateur temporaire pour la navigation
      _user = User.fromJson(response);
      _currentUserId = _user!.id;
      await StorageService.saveUser(_user!);

      // Nettoyer le contexte de bâtiment car l'utilisateur doit choisir
      BuildingContextService().clearBuildingContext();

      notifyListeners();
      return;
    }

    final token = response['token'];
    final refreshToken = response['refreshToken'];

    if (token != null) {
      await StorageService.saveToken(token);
    }
    if (refreshToken != null) {
      await StorageService.saveRefreshToken(refreshToken);
    }

    _user = User.fromJson(response);
    _currentUserId = _user!.id;
    print('DEBUG: User logged in with ID: ${_user!.id}'); // Debug log
    await StorageService.saveUser(_user!);

    // Mettre à jour le contexte de bâtiment
    if (_user!.buildingId != null) {
      BuildingContextService().setBuildingContext(_user!.buildingId!);
      print('DEBUG: Building context set to: ${_user!.buildingId}');
    }

    await _connectWebSocket();
    notifyListeners();
  }

  Future<bool> selectBuilding(String buildingId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.selectBuilding(buildingId);

      // Mettre à jour immédiatement le contexte de bâtiment
      BuildingContextService().setBuildingContext(buildingId);
      print('DEBUG: Building context updated to: $buildingId before handling response');

      await _handleLoginSuccess(response);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Méthode pour nettoyer les données des autres providers
  void clearAllProvidersData() {
    // Cette méthode sera appelée depuis les écrans qui ont accès aux providers
    print('DEBUG: clearAllProvidersData called from AuthProvider');
  }
  Future<List<dynamic>> getUserBuildings() async {
    try {
      return await _apiService.getUserBuildings();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<void> loadAvailableBuildings() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      final buildings = await _apiService.getUserBuildings();
      _availableBuildings = buildings
          .map((json) => BuildingSelection.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _availableBuildings = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      await _wsService.connect();
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }

  Future<void> logout() async {
    _wsService.disconnect();
    BuildingContextService().clearBuildingContext();
    await StorageService.clearAll();
    _user = null;
    _clearError();
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    _user = updatedUser;
    StorageService.saveUser(updatedUser);
    notifyListeners();
  }

  Future<String?> getToken() async {
    return await StorageService.getToken();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}