import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/channel_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/vote_provider.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';

class BuildingContextService {
  static final BuildingContextService _instance = BuildingContextService._internal();
  factory BuildingContextService() => _instance;
  BuildingContextService._internal();

  String? _currentBuildingId;
  String? _previousBuildingId;

  String? get currentBuildingId => _currentBuildingId;
  String? get previousBuildingId => _previousBuildingId;

  void setBuildingContext(String buildingId) {
    if (_currentBuildingId != buildingId) {
      print('DEBUG: Building context changed from $_currentBuildingId to $buildingId');
      _previousBuildingId = _currentBuildingId;
      _currentBuildingId = buildingId;

      // Sauvegarder le contexte actuel
      _saveBuildingContext(buildingId);
    }
  }

  void _saveBuildingContext(String buildingId) async {
    await StorageService.setString('current_building_id', buildingId);
    print('DEBUG: Building context saved: $buildingId');
  }

  Future<void> loadBuildingContext() async {
    final savedBuildingId = StorageService.getString('current_building_id');
    if (savedBuildingId.isNotEmpty) {
      _currentBuildingId = savedBuildingId;
      print('DEBUG: Building context loaded from storage: $savedBuildingId');
    }
  }

  void clearBuildingContext() {
    print('DEBUG: Clearing building context');
    _previousBuildingId = _currentBuildingId;
    _currentBuildingId = null;
    StorageService.setString('current_building_id', '');
  }

  static void clearAllProvidersData(BuildContext context) {
    try {
      print('DEBUG: Clearing all providers data for building switch');

      // Nettoyer WebSocket en premier
      final wsService = WebSocketService();
      wsService.clearAllSubscriptions();

      // Nettoyer tous les providers
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final voteProvider = Provider.of<VoteProvider>(context, listen: false);

      chatProvider.clearAllData();
      channelProvider.clearAllData();
      notificationProvider.clearAllNotifications();
      voteProvider.clearAllData();

      print('DEBUG: All providers data cleared successfully');
    } catch (e) {
      print('DEBUG: Error clearing providers data: $e');
    }
  }

  static void loadDataForCurrentBuilding(BuildContext context) {
    try {
      print('DEBUG: Loading data for current building');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

      final currentBuildingId = authProvider.user?.buildingId;

      if (currentBuildingId != null) {
        // Mettre à jour le contexte
        BuildingContextService().setBuildingContext(currentBuildingId);

        // Charger les données
        channelProvider.loadChannels(refresh: true);

        // Charger les résidents du bâtiment actuel
        channelProvider.loadBuildingResidents(currentBuildingId);

        print('DEBUG: Data loading initiated for building: $currentBuildingId');
      } else {
        print('DEBUG: No current building ID found');
      }
    } catch (e) {
      print('DEBUG: Error loading data for current building: $e');
    }
  }

  static void forceRefreshForBuilding(BuildContext context, String buildingId) {
    try {
      print('DEBUG: Force refreshing data for building: $buildingId');

      // Nettoyer d'abord
      clearAllProvidersData(context);

      // Mettre à jour le contexte
      BuildingContextService().setBuildingContext(buildingId);

      // Attendre un peu pour que le nettoyage soit effectif
      Future.delayed(const Duration(milliseconds: 200), () {
        final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

        // Charger les nouvelles données
        channelProvider.loadChannels(refresh: true);
        channelProvider.loadBuildingResidents(buildingId);

        print('DEBUG: Force refresh completed for building: $buildingId');
      });
    } catch (e) {
      print('DEBUG: Error in force refresh: $e');
    }
  }

  static void refreshCurrentBuildingData(BuildContext context) {
    print('DEBUG: Refreshing current building data');
    clearAllProvidersData(context);

    // Attendre un peu pour que le nettoyage soit effectif
    Future.delayed(const Duration(milliseconds: 100), () {
      loadDataForCurrentBuilding(context);
    });
  }
}