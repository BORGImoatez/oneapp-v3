import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/building_selection_model.dart';
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
import '../apartment/my_apartment_screen.dart';
import '../claims/claims_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _lastBuildingId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

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
    _animationController.dispose();
    NotificationService().onNotificationReceived = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (_lastBuildingId != currentBuildingId) {
      _lastBuildingId = currentBuildingId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentBuildingId != null) {
          _initializeForCurrentBuilding();
        }
      });
    }
  }

  void _initializeForCurrentBuilding() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      BuildingContextService.clearAllProvidersData(context);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          BuildingContextService.forceRefreshForBuilding(context, currentBuildingId);
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.loadUnreadCountForBuilding(currentBuildingId);
        }
      });
    }
  }

  void _refreshHomeData() {
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

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.exit_to_app,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Quitter l'application ?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir quitter ?",
          style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Quitter",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                _initializeForCurrentBuilding();
              },
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildNotificationsSummary(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildQuickAccess(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildRecentActivity(),
                    ),
                  ),
                ],
              ),
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
        final hour = DateTime.now().hour;
        String greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$greeting, ${user?.fname ?? 'Utilisateur'}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    const BuildingSelectorDropdown(),
                    const SizedBox(width: 8),
                    _buildNotificationButton(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const BuildingContextIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final hasNotifications = notificationProvider.totalNotifications > 0;

        return IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                hasNotifications ? Icons.notifications_active : Icons.notifications_outlined,
                color: AppTheme.textSecondary,
              ),
              if (hasNotifications)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationProvider.totalNotifications > 9
                          ? '9+'
                          : '${notificationProvider.totalNotifications}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
          subtitle: notificationProvider.totalNotifications > 1
              ? '${notificationProvider.totalNotifications} nouvelles notifications'
              : '${notificationProvider.totalNotifications} nouvelle notification',
          icon: Icons.notifications_active,
          color: AppTheme.warningColor,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Consumer2<ChannelProvider, AuthProvider>(
          builder: (context, channelProvider, authProvider, child) {
            final recentChannels = channelProvider.channels.take(2).toList();
            final screenWidth = MediaQuery.of(context).size.width;
            final isAdmin = authProvider.user?.role == 'BUILDING_ADMIN';

            final quickAccessItems = <Widget>[
              if (authProvider.user?.apartmentId != null)
                QuickAccessCard(
                  title: 'Mon Appartement',
                  subtitle: 'Gérer les détails',
                  icon: Icons.home_rounded,
                  color: Colors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MyApartmentScreen(
                          apartmentId: authProvider.user!.apartmentId!,
                        ),
                      ),
                    );
                  },
                ),
              QuickAccessCard(
                title: 'Dernier Chat',
                subtitle: recentChannels.isNotEmpty
                    ? recentChannels.first.name
                    : 'Aucun chat récent',
                icon: Icons.chat_bubble_rounded,
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
                icon: Icons.forum_rounded,
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
              QuickAccessCard(
                title: 'Sinistres',
                subtitle: 'Déclarer un sinistre',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ClaimsScreen(),
                    ),
                  );
                },
              ),
              if (isAdmin)
                QuickAccessCard(
                  title: 'Gestion Immeuble',
                  subtitle: 'Ajouter des biens',
                  icon: Icons.admin_panel_settings_rounded,
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
              childAspectRatio: screenWidth < 360 ? 1.8 : 2.0,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ChannelProvider>(
          builder: (context, channelProvider, child) {
            if (channelProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final recentChannels = channelProvider.channels.take(5).toList();

            if (recentChannels.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune activité récente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vos conversations apparaîtront ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentChannels.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 72,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final channel = recentChannels[index];
                  final isFirst = index == 0;
                  final isLast = index == recentChannels.length - 1;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(channel: channel),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(16) : Radius.zero,
                        bottom: isLast ? const Radius.circular(16) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.8),
                                    AppTheme.primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                channel.type == 'ONE_TO_ONE'
                                    ? Icons.person_rounded
                                    : Icons.group_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    channel.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    channel.lastMessage?.content ?? 'Aucun message',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (channel.lastMessage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTime(channel.lastMessage!.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
      return 'Now';
    }
  }
}