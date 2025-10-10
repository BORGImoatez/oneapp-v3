import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/building_context_service.dart';
import '../../widgets/building_context_indicator.dart';
import '../../utils/app_theme.dart';
import '../../models/channel_model.dart';
import 'chat_screen.dart';
import 'new_discussion_screen.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  String? _lastBuildingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForCurrentBuilding();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Vérifier si le bâtiment a changé
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (_lastBuildingId != currentBuildingId) {
      print('DEBUG: DiscussionsScreen - Building changed from $_lastBuildingId to $currentBuildingId');
      _lastBuildingId = currentBuildingId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentBuildingId != null) {
          _initializeForCurrentBuilding();
        }
      });
    }
  }

  void _initializeForCurrentBuilding() {
    print('DEBUG: DiscussionsScreen - Initializing for current building');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      BuildingContextService.forceRefreshForBuilding(context, currentBuildingId);
    }
  }

  void _loadDiscussions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId == null) {
      print('DEBUG: No building context, skipping discussions load');
      return;
    }

    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
    channelProvider.loadChannels(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Discussions'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          const BuildingContextIndicator(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NewDiscussionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: Consumer<ChannelProvider>(
        builder: (context, channelProvider, child) {
          if (channelProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (channelProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${channelProvider.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDiscussions,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final directChannels = channelProvider.getDirectChannels();

          if (directChannels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune discussion',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez une nouvelle discussion',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NewDiscussionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle discussion'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadDiscussions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: directChannels.length,
              itemBuilder: (context, index) {
                final channel = directChannels[index];
                return _buildDiscussionCard(channel);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "discussions_fab",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewDiscussionScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDiscussionCard(Channel channel) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isReceivedMessage = channel.lastMessage != null &&
                              channel.lastMessage!.senderId != currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isReceivedMessage ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: const Icon(
            Icons.person,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          channel.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: channel.lastMessage != null
            ? Text(
          channel.lastMessage!.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isReceivedMessage ? Colors.blue[900] : Colors.grey[600],
            fontWeight: isReceivedMessage ? FontWeight.w500 : FontWeight.normal,
          ),
        )
            : Text(
          'Aucun message',
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (channel.lastMessage != null)
              Text(
                _formatTime(channel.lastMessage!.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isReceivedMessage ? Colors.blue[700] : AppTheme.textSecondary,
                  fontWeight: isReceivedMessage ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            if (isReceivedMessage) ..[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(channel: channel),
            ),
          );
        },
      ),
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