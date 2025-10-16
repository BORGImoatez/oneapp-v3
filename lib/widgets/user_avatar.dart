import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class UserAvatar extends StatelessWidget {
  final String? profilePictureUrl;
  final String firstName;
  final String lastName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.profilePictureUrl,
    required this.firstName,
    required this.lastName,
    this.radius = 16,
  });

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primaryColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            '${ApiConstants.baseUrl.replaceAll('/api/v1', '')}$profilePictureUrl',
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.75,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
