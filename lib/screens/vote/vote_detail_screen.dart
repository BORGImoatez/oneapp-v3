import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vote_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/channel_model.dart';
import '../../models/vote_model.dart';
import '../../widgets/custom_button.dart';

class VoteDetailScreen extends StatefulWidget {
  final Vote vote;
  final Channel channel;
  final bool isAdmin;

  const VoteDetailScreen({
    super.key,
    required this.vote,
    required this.channel,
    required this.isAdmin,
  });

  @override
  State<VoteDetailScreen> createState() => _VoteDetailScreenState();
}

class _VoteDetailScreenState extends State<VoteDetailScreen> {
  final List<int> _selectedOptions = [];
  late Vote _currentVote;

  @override
  void initState() {
    super.initState();
    _currentVote = widget.vote;
    _loadVoteDetails();
  }

  void _loadVoteDetails() {
    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    voteProvider.loadVoteDetails(_currentVote.id);
  }

  void _submitVote() async {
    if (_selectedOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une option'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final voteProvider = Provider.of<VoteProvider>(context, listen: false);

    final success = await voteProvider.submitVote({
      'voteId': _currentVote.id,
      'selectedOptionIds': _selectedOptions,
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote enregistré avec succès !'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _closeVote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fermer le vote'),
        content: const Text('Êtes-vous sûr de vouloir fermer ce vote ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final voteProvider = Provider.of<VoteProvider>(context, listen: false);
      final success = await voteProvider.closeVote(_currentVote.id);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote fermé avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _currentVote.endDate != null &&
        _currentVote.endDate!.isBefore(DateTime.now());
    final canVote = _currentVote.isActive && !_currentVote.hasVoted && !isExpired;
    final showResults = _currentVote.hasVoted || !_currentVote.isActive || isExpired;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Détails du vote'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isAdmin && _currentVote.isActive)
            IconButton(
              onPressed: _closeVote,
              icon: const Icon(Icons.close, color: AppTheme.errorColor),
            ),
        ],
      ),
      body: Consumer<VoteProvider>(
        builder: (context, voteProvider, child) {
          // Mettre à jour le vote si disponible
          final updatedVote = voteProvider.getVoteById(_currentVote.id);
          if (updatedVote != null) {
            _currentVote = updatedVote;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vote Header
                _buildVoteHeader(),

                const SizedBox(height: 24),

                // Vote Options
                _buildVoteOptions(canVote, showResults),

                const SizedBox(height: 24),

                // Vote Button
                if (canVote)
                  CustomButton(
                    text: 'Soumettre mon vote',
                    onPressed: voteProvider.isLoading ? null : _submitVote,
                    isLoading: voteProvider.isLoading,
                    icon: Icons.how_to_vote,
                  ),

                // Results Summary
                if (showResults)
                  _buildResultsSummary(),

                // Error Message
                if (voteProvider.error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      voteProvider.error!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoteHeader() {
    final isExpired = _currentVote.endDate != null &&
        _currentVote.endDate!.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentVote.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(isExpired),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _currentVote.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${_currentVote.totalVotes} vote(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                _currentVote.voteType == 'SINGLE_CHOICE'
                    ? Icons.radio_button_checked
                    : Icons.check_box,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _currentVote.voteType == 'SINGLE_CHOICE' ? 'Choix unique' : 'Choix multiple',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          if (_currentVote.endDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Se termine le ${_formatDate(_currentVote.endDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteOptions(bool canVote, bool showResults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        ..._currentVote.options.map((option) {
          final isSelected = _selectedOptions.contains(option.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: canVote ? () {
                setState(() {
                  if (_currentVote.voteType == 'SINGLE_CHOICE') {
                    _selectedOptions.clear();
                    if (!isSelected) {
                      _selectedOptions.add(option.id);
                    }
                  } else {
                    if (isSelected) {
                      _selectedOptions.remove(option.id);
                    } else {
                      _selectedOptions.add(option.id);
                    }
                  }
                });
              } : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (canVote)
                          Icon(
                            _currentVote.voteType == 'SINGLE_CHOICE'
                                ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
                                : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                            color: isSelected ? AppTheme.primaryColor : Colors.grey,
                          )
                        else
                          Icon(
                            _currentVote.voteType == 'SINGLE_CHOICE'
                                ? Icons.radio_button_unchecked
                                : Icons.check_box_outline_blank,
                            color: Colors.grey,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (showResults) ...[
                          Text(
                            '${option.voteCount}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${option.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (showResults) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: option.percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildResultsSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résultats du vote',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.how_to_vote, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(
                'Total des votes: ${_currentVote.totalVotes}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_currentVote.hasVoted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.successColor),
                const SizedBox(width: 8),
                const Text(
                  'Vous avez participé à ce vote',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isExpired) {
    Color color;
    String text;
    IconData icon;

    if (!_currentVote.isActive) {
      color = Colors.grey;
      text = 'Fermé';
      icon = Icons.lock;
    } else if (isExpired) {
      color = AppTheme.errorColor;
      text = 'Expiré';
      icon = Icons.schedule;
    } else if (_currentVote.hasVoted) {
      color = AppTheme.successColor;
      text = 'Voté';
      icon = Icons.check;
    } else {
      color = AppTheme.warningColor;
      text = 'En cours';
      icon = Icons.poll;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}