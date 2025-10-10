import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final int? badge;

  const QuickAccessCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: isSmallScreen ? 32 : 40,
                    height: isSmallScreen ? 32 : 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
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
              SizedBox(height: isSmallScreen ? 8 : 12),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}