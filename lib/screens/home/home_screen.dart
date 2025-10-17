import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/building_context_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/building_context_indicator.dart';
import '../../utils/app_theme.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/quick_access_card.dart';
import '../../widgets/building_selector_dropdown.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import '../admin/admin_building_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastBuildingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForCurrentBuilding();
    });

    NotificationService().onNotificationReceived = () {
      if (mounted) {
        _refreshHomeData();
      }
    };
  }

  @override
  void dispose() {
    NotificationService().onNotificationReceived = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Vérifier si le bâtiment a changé
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (_lastBuildingId != currentBuildingId) {
      print('DEBUG: HomeScreen - Building changed from $_lastBuildingId to $currentBuildingId');
      _lastBuildingId = currentBuildingId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentBuildingId != null) {
          _initializeForCurrentBuilding();
        }
      });
    }
  }


  void _initializeForCurrentBuilding() {
    print('DEBUG: HomeScreen - Initializing for current building');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      // Nettoyer et charger les données pour le bâtiment actuel
      BuildingContextService.clearAllProvidersData(context);

      // Attendre un peu puis charger
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          BuildingContextService.forceRefreshForBuilding(context, currentBuildingId);

          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.loadUnreadCountForBuilding(currentBuildingId);
        }
      });
    }
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId == null) {
      print('DEBUG: No building context, skipping data load');
      return;
    }

    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
    channelProvider.loadChannels(refresh: true);

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.loadUnreadCountForBuilding(currentBuildingId);
  }

  void _refreshHomeData() {
    print('DEBUG: HomeScreen - Refreshing home data after notification');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
      channelProvider.loadChannels(refresh: true);

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.loadUnreadCountForBuilding(currentBuildingId);

      if (mounted) {
        setState(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _initializeForCurrentBuilding();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 24),

                // Notifications Summary
                _buildNotificationsSummary(),

                const SizedBox(height: 24),

                // Quick Access
                _buildQuickAccess(),

                const SizedBox(height: 24),

                // Recent Activity
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final isSmallScreen = MediaQuery.of(context).size.width < 360;

        return Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 20 : 25,
                  backgroundColor: AppTheme.primaryColor,
                  child: user?.picture != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                    child: Image.network(
                      user!.picture!,
                      width: isSmallScreen ? 40 : 50,
                      height: isSmallScreen ? 40 : 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          user.initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        );
                      },
                    ),
                  )
                      : Text(
                    user?.initials ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${user?.fname ?? 'Utilisateur'}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user?.apartmentId != null)
                        Text(
                          'Appartement ${user!.apartmentId}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const BuildingSelectorDropdown(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return Stack(
                        children: [
                          const Icon(Icons.notifications_outlined),
                          if (notificationProvider.totalNotifications > 0)
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
                                  '${notificationProvider.totalNotifications}',
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
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const BuildingContextIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsSummary() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.totalNotifications == 0) {
          return const SizedBox.shrink();
        }

        return NotificationCard(
          title: 'Notifications',
          subtitle: '${notificationProvider.totalNotifications} nouvelle(s) notification(s)',
          icon: Icons.notifications,
          color: AppTheme.warningColor,
          onTap: () {
            // TODO: Navigate to notifications screen
          },
        );
      },
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accès rapide',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Consumer2<ChannelProvider, AuthProvider>(
          builder: (context, channelProvider, authProvider, child) {
            final recentChannels = channelProvider.channels.take(2).toList();
            final screenWidth = MediaQuery.of(context).size.width;
            final isAdmin = authProvider.user?.isAdmin ?? false;

            final quickAccessItems = <Widget>[
              QuickAccessCard(
                title: 'Dernier Chat',
                subtitle: recentChannels.isNotEmpty
                    ? recentChannels.first.name
                    : 'Aucun chat récent',
                icon: Icons.chat,
                color: AppTheme.primaryColor,
                onTap: () {
                  if (recentChannels.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          channel: recentChannels.first,
                        ),
                      ),
                    );
                  }
                },
              ),
              QuickAccessCard(
                title: 'Dernier Canal',
                subtitle: recentChannels.length > 1
                    ? recentChannels[1].name
                    : 'Aucun canal récent',
                icon: Icons.forum,
                color: AppTheme.accentColor,
                onTap: () {
                  if (recentChannels.length > 1) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          channel: recentChannels[1],
                        ),
                      ),
                    );
                  }
                },
              ),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return QuickAccessCard(
                    title: 'Notifications',
                    subtitle: notificationProvider.unreadNotifications > 0
                        ? '${notificationProvider.unreadNotifications} non lue${notificationProvider.unreadNotifications > 1 ? 's' : ''}'
                        : 'Aucune notification',
                    icon: Icons.notifications,
                    color: AppTheme.warningColor,
                    badge: notificationProvider.unreadNotifications > 0
                        ? notificationProvider.unreadNotifications
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              if (isAdmin)
                QuickAccessCard(
                  title: 'Gestion Immeuble',
                  subtitle: 'Ajouter des biens',
                  icon: Icons.admin_panel_settings,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminBuildingScreen(),
                      ),
                    );
                  },
                ),
            ];

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: screenWidth < 360 ? 1.0 : 1.2,
              children: quickAccessItems,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ChannelProvider>(
          builder: (context, channelProvider, child) {
            if (channelProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final recentChannels = channelProvider.channels.take(5).toList();

            if (recentChannels.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune activité récente',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentChannels.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final channel = recentChannels[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        channel.type == 'ONE_TO_ONE'
                            ? Icons.person
                            : Icons.group,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      channel.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      channel.lastMessage?.content ?? 'Aucun message',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: channel.lastMessage != null
                        ? Text(
                      _formatTime(channel.lastMessage!.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    )
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(channel: channel),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'maintenant';
    }
  }
}