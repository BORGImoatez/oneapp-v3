t('Resume failed, trying to play from start: $e');
          await _audioPlayer.play(DeviceFileSource(_localFilePath!));
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la lecture audio: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isMe ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              )
                  : Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isMe ? Colors.white : AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre de progression
                GestureDetector(
                  onTapDown: (details) {
                    if (_duration.inMilliseconds > 0) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.globalPosition);
                      final progress = localPosition.dx / box.size.width;
                      final newPosition = Duration(
                        milliseconds: (_duration.inMilliseconds * progress).round(),
                      );
                      _audioPlayer.seek(newPosition);
                    }
                  },
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: _duration.inMilliseconds > 0
                        ? LinearProgressIndicator(
                      value: _position.inMilliseconds / _duration.inMilliseconds,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white70 : AppTheme.primaryColor,
                      ),
                    )
                        : LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white70 : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Durée
                Text(
                  _duration.inMilliseconds > 0
                      ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                      : _isLoading ? 'Chargement...' : 'Message vocal',
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallMessage(BuildContext context) {
    if (message.callData == null) {
      return Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : AppTheme.textPrimary,
          fontSize: 16,
        ),
      );
    }

    final callData = message.callData!;
    final callStatus = callData['status'] as String;
    final createdAt = callData['createdAt'] != null
        ? DateTime.parse(callData['createdAt'].toString())
        : message.createdAt;

    IconData callIcon;
    Color iconColor;
    String statusText;

    if (callStatus == 'MISSED') {
      callIcon = Icons.phone_missed;
      iconColor = Colors.red;
      statusText = 'Appel manqué';
    } else if (callStatus == 'REJECTED') {
      callIcon = Icons.phone_disabled;
      iconColor = Colors.orange;
      statusText = 'Appel refusé';
    } else if (callStatus == 'FAILED') {
      callIcon = Icons.phone_disabled;
      iconColor = Colors.red;
      statusText = 'Appel échoué';
    } else {
      callIcon = isMe ? Icons.call_made : Icons.call_received;
      iconColor = Colors.green;
      statusText = isMe ? 'Appel passé' : 'Appel reçu';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                callIcon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: (callStatus == 'MISSED' || callStatus == 'FAILED')
                          ? Colors.red
                          : (isMe ? Colors.white : AppTheme.textPrimary),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCallTime(createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (callData['durationSeconds'] != null &&
                      callData['durationSeconds'] > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(callData['durationSeconds']),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _handleRecall(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Rappeler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCallTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('HH:mm');

    if (callDate == today) {
      return "Aujourd'hui à ${timeFormat.format(dateTime)}";
    } else if (callDate == yesterday) {
      return "Hier à ${timeFormat.format(dateTime)}";
    } else {
      return DateFormat('dd/MM/yyyy à HH:mm').format(dateTime);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}min ${remainingSeconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _handleRecall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction de rappel en cours de développement'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}