import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/call_model.dart';
import '../utils/app_theme.dart';

class CallMessageWidget extends StatelessWidget {
  final CallModel call;
  final bool isOutgoing;
  final VoidCallback onCallBack;

  const CallMessageWidget({
    Key? key,
    required this.call,
    required this.isOutgoing,
    required this.onCallBack,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final isMissed = call.status == 'MISSED';
    final isRejected = call.status == 'REJECTED';
    final isFailed = call.status == 'FAILED';

    IconData callIcon;
    Color iconColor;
    String statusText;

    if (isMissed) {
      callIcon = isOutgoing ? Icons.phone_missed : Icons.phone_missed;
      iconColor = Colors.red;
      statusText = isOutgoing ? 'Appel manqué' : 'Appel manqué';
    } else if (isRejected) {
      callIcon = Icons.phone_disabled;
      iconColor = Colors.orange;
      statusText = 'Appel refusé';
    } else if (isFailed) {
      callIcon = Icons.phone_disabled;
      iconColor = Colors.red;
      statusText = 'Appel échoué';
    } else {
      callIcon = isOutgoing ? Icons.phone_callback : Icons.phone_in_talk;
      iconColor = Colors.green;
      statusText = 'Appel terminé';
    }

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOutgoing
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutgoing
                ? AppTheme.primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                callIcon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: isMissed || isFailed ? Colors.red : Colors.grey[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCallTime(call.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (call.durationSeconds != null &&
                    call.durationSeconds! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    call.getFormattedDuration(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            Material(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onCallBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Rappeler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
