import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/building_context_service.dart';

class ChannelProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Channel> _channels = [];
  List<User> _buildingResidents = [];
  bool _isLoading = false;
  String? _error;
  String? _currentBuildingContext;

  List<Channel> get channels => _channels;
  List<User> get buildingResidents => _buildingResidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChannels({bool refresh = false}) async {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;

    // Ne pas charger si pas de contexte de bâtiment
    if (currentBuildingId == null) {
      print('DEBUG: No building context, skipping channels load');
      _setLoading(false);
      return;
    }

    // Si le contexte a changé ou refresh, on nettoie
    if (_currentBuildingContext != currentBuildingId) {
      print('DEBUG: Building context changed from $_currentBuildingContext to $currentBuildingId, clearing channels data');
      _channels.clear();
      _currentBuildingContext = currentBuildingId;
      notifyListeners();
    }

    // Éviter les chargements multiples sauf si refresh
    if (_isLoading && !refresh) {
      print('DEBUG: Already loading, skipping');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      print('DEBUG: Loading channels for building context: $currentBuildingId');
      final response = await _apiService.getChannels();

      List<Channel> loadedChannels = (response['content'] as List)
          .map((json) => Channel.fromJson(json))
          .toList();

      print('DEBUG: Received ${loadedChannels.length} channels from API');

      // Filtrer les canaux pour ne garder que ceux du bâtiment actuel
      _channels = loadedChannels.where((channel) {
        // Toujours garder les discussions ONE_TO_ONE
        if (channel.type == 'ONE_TO_ONE') return true;

        // Garder les canaux sans bâtiment spécifique (PUBLIC, etc.)
        if (channel.buildingId == null) return true;

        // Garder seulement les canaux du bâtiment actuel
        return channel.buildingId == currentBuildingId;
      }).toList();

      print('DEBUG: Filtered to ${_channels.length} channels for building: $currentBuildingId');

      // Sort channels by last activity
      _channels.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.createdAt;
        final bTime = b.lastMessage?.createdAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      print('DEBUG: Channels sorted by last activity');

    } catch (e) {
      print('DEBUG: Error loading channels: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Channel?> getOrCreateDirectChannel(String otherUserId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getOrCreateDirectChannel(otherUserId);
      final channel = Channel.fromJson(response);

      // Add to channels list if not exists
      if (!_channels.any((c) => c.id == channel.id)) {
        _channels.insert(0, channel);
        notifyListeners();
      }

      return channel;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Channel?> createChannel(Map<String, dynamic> channelData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createChannel(channelData);
      final channel = Channel.fromJson(response);

      _channels.insert(0, channel);
      notifyListeners();

      return channel;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBuildingResidents(String buildingId) async {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (buildingId != "current" && buildingId != currentBuildingId && currentBuildingId != null) {
      print('DEBUG: Requested building $buildingId does not match current context $currentBuildingId');
      return;
    }

    // Si pas de contexte de bâtiment, ne pas charger
    if (currentBuildingId == null && buildingId == "current") {
      print('DEBUG: No building context, skipping residents load');
      return;
    }

    print('DEBUG: Loading residents for building context: $currentBuildingId');
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getBuildingResidents("current");
      print('DEBUG: API response: $response');

      // Forcer à extraire la liste même si ApiService renvoie Map
      final residentsList = (response as dynamic) as List<dynamic>;

      _buildingResidents = residentsList
          .map((json) => User.fromJson(json))
          .toList();
  print(_buildingResidents.length);
      // Filtrer pour s'assurer qu'on n'a que les résidents du bâtiment actuel
      if (currentBuildingId != null) {
        _buildingResidents = _buildingResidents
            .where((resident) => resident.buildingId == currentBuildingId || resident.buildingId == null)
            .toList();
      }

      print('DEBUG: Parsed ${_buildingResidents.length} residents for building: $currentBuildingId');
      for (var resident in _buildingResidents) {
        print('DEBUG: Resident: ${resident.fullName} (Building: ${resident.buildingId})');
      }
    } catch (e) {
      print('DEBUG: Error loading residents: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }


  Channel? getChannelById(int channelId) {
    try {
      return _channels.firstWhere((channel) => channel.id == channelId);
    } catch (e) {
      return null;
    }
  }

  List<Channel> getDirectChannels() {
    print('DEBUG: Getting direct channels from ${_channels.length} total channels');
    for (var channel in _channels) {
      print('DEBUG: Channel ${channel.id} - ${channel.name} - Type: ${channel.type}');
    }
    final directChannels = _channels.where((c) => c.type == 'ONE_TO_ONE').toList();
    print('DEBUG: Found ${directChannels.length} direct channels');
    return directChannels;
  }

  List<Channel> getGroupChannels() {
    return _channels.where((c) => c.type == 'GROUP').toList();
  }

  List<Channel> getBuildingChannels() {
    return _channels.where((c) => c.type == 'BUILDING').toList();
  }

  void updateChannelLastMessage(int channelId, Message lastMessage) {
    final channelIndex = _channels.indexWhere((c) => c.id == channelId);
    if (channelIndex != -1) {
      final updatedChannel = Channel(
        id: _channels[channelIndex].id,
        name: _channels[channelIndex].name,
        description: _channels[channelIndex].description,
        type: _channels[channelIndex].type,
        buildingId: _channels[channelIndex].buildingId,
        buildingGroupId: _channels[channelIndex].buildingGroupId,
        createdBy: _channels[channelIndex].createdBy,
        isActive: _channels[channelIndex].isActive,
        isPrivate: _channels[channelIndex].isPrivate,
        createdAt: _channels[channelIndex].createdAt,
        updatedAt: _channels[channelIndex].updatedAt,
        memberCount: _channels[channelIndex].memberCount,
        lastMessage: lastMessage,
      );

      _channels[channelIndex] = updatedChannel;

      // Move to top of list
      _channels.removeAt(channelIndex);
      _channels.insert(0, updatedChannel);

      notifyListeners();
    }
  }

  void clearAllData() {
    _channels.clear();
    _buildingResidents.clear();
    _isLoading = false;
    _error = null;
    _currentBuildingContext = null;
    notifyListeners();
  }

  void clearBuildingResidents() {
    _buildingResidents.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  void forceRefreshForBuilding(String buildingId) {
    print('DEBUG: Force refreshing channels for building: $buildingId');

    // Nettoyer les données existantes
    _channels.clear();
    _buildingResidents.clear();
    _currentBuildingContext = buildingId;

    // Recharger immédiatement
    loadChannels(refresh: true);
    loadBuildingResidents(buildingId);
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