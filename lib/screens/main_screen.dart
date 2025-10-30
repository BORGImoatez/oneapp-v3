import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/channel_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/vote_provider.dart';
import '../providers/call_provider.dart';
import '../services/building_context_service.dart';
import '../utils/app_theme.dart';
import 'home/home_screen.dart';
import 'channels/channels_screen.dart';
import 'chat/discussions_screen.dart';
import 'files/files_screen.dart';
import 'settings/settings_screen.dart';
import 'call/incoming_call_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _lastBuildingId;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChannelsScreen(),
    const DiscussionsScreen(),
    const FilesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataForCurrentBuilding();
      _setupCallListener();
    });
  }

  void _setupCallListener() {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.addListener(() {
      if (callProvider.currentCall != null && !callProvider.isInCall) {
        _showIncomingCallScreen(callProvider.currentCall!);
      }
    });
  }

  void _showIncomingCallScreen(call) {
    final callProvider = Provider.of<CallProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(
          call: call,
          webrtcService: callProvider.webrtcService,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Vérifier si le bâtiment a changé
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (_lastBuildingId != currentBuildingId) {
      print('DEBUG: Building changed from $_lastBuildingId to $currentBuildingId');
      _lastBuildingId = currentBuildingId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentBuildingId != null) {
          _refreshDataForCurrentBuilding();
        }
      });
    }
  }

  void _refreshDataForCurrentBuilding() {
    print('DEBUG: Refreshing data for current building in MainScreen');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      // Nettoyer toutes les données existantes
      BuildingContextService.clearAllProvidersData(context);

      // Attendre un peu puis charger les nouvelles données
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          BuildingContextService.forceRefreshForBuilding(context, currentBuildingId);
        }
      });
    }

    print('DEBUG: Data refresh completed for current building');
  }

  void _onTabChanged(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId == null) return;

    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

    // Index 1 = Canaux, Index 2 = Discussions
    if (index == 1 || index == 2) {
      print('DEBUG: Tab changed to ${index == 1 ? "Channels" : "Discussions"}, reloading data');
      channelProvider.loadChannels(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });

              // Recharger les données quand on change d'onglet
              _onTabChanged(index);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
            backgroundColor: Colors.white,
            elevation: 8,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.forum_outlined),
                    if (notificationProvider.unreadMessages > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notificationProvider.unreadMessages}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.forum),
                label: 'Canaux',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_outlined),
                activeIcon: Icon(Icons.chat),
                label: 'Discussions',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.folder_outlined),
                    if (notificationProvider.newFiles > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notificationProvider.newFiles}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.folder),
                label: 'Fichiers',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Paramètres',
              ),
            ],
          );
        },
      ),
    );
  }
}