import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vote_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/channel_model.dart';
import '../../models/vote_model.dart';
import 'create_vote_screen.dart';
import 'vote_detail_screen.dart';

class VoteScreen extends StatefulWidget {
  final Channel channel;

  const VoteScreen({super.key, required this.channel});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVotes();
    });
  }

  void _loadVotes() {
    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    voteProvider.loadChannelVotes(widget.channel.id);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAdmin = user?.role == 'BUILDING_ADMIN' || 
                   user?.role == 'GROUP_ADMIN' || 
                   user?.role == 'SUPER_ADMIN';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Votes - ${widget.channel.name}'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateVoteScreen(channel: widget.channel),
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Consumer<VoteProvider>(
        builder: (context, voteProvider, child) {
          if (voteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (voteProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${voteProvider.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadVotes,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final votes = voteProvider.getChannelVotes(widget.channel.id);

          if (votes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.poll_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun vote',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin 
                        ? 'Créez votre premier vote'
                        : 'Aucun vote disponible pour le moment',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateVoteScreen(channel: widget.channel),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un vote'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadVotes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: votes.length,
              itemBuilder: (context, index) {
                final vote = votes[index];
                return _buildVoteCard(vote, isAdmin);
              },
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: "vote_fab",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateVoteScreen(channel: widget.channel),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildVoteCard(Vote vote, bool isAdmin) {
    final isExpired = vote.endDate != null && vote.endDate!.isBefore(DateTime.now());
    final canVote = vote.isActive && !vote.hasVoted && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VoteDetailScreen(
                vote: vote,
                channel: widget.channel,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vote.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildVoteStatusChip(vote, isExpired),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                vote.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${vote.totalVotes} vote(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    vote.voteType == 'SINGLE_CHOICE' ? Icons.radio_button_checked : Icons.check_box,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vote.voteType == 'SINGLE_CHOICE' ? 'Choix unique' : 'Choix multiple',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (vote.endDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatEndDate(vote.endDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              
              if (canVote) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VoteDetailScreen(
                            vote: vote,
                            channel: widget.channel,
                            isAdmin: isAdmin,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Voter'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteStatusChip(Vote vote, bool isExpired) {
    Color color;
    String text;
    IconData icon;

    if (!vote.isActive) {
      color = Colors.grey;
      text = 'Fermé';
      icon = Icons.lock;
    } else if (isExpired) {
      color = AppTheme.errorColor;
      text = 'Expiré';
      icon = Icons.schedule;
    } else if (vote.hasVoted) {
      color = AppTheme.successColor;
      text = 'Voté';
      icon = Icons.check;
    } else {
      color = AppTheme.warningColor;
      text = 'En cours';
      icon = Icons.poll;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatEndDate(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Expiré';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j restant';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h restant';
    } else {
      return '${difference.inMinutes}m restant';
    }
  }
}