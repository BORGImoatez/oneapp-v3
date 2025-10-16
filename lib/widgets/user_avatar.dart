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
    print('DEBUG UserAvatar: profilePictureUrl=$profilePictureUrl, firstName=$firstName, lastName=$lastName');

    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      final imageUrl = '${ApiConstants.baseUrl}$profilePictureUrl';
      print('DEBUG UserAvatar: Loading image from: $imageUrl');

      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primaryColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                print('DEBUG UserAvatar: Image loaded successfully');
                return child;
              }
              print('DEBUG UserAvatar: Loading image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('DEBUG UserAvatar: Error loading image: $error');
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

    print('DEBUG UserAvatar: No profile picture, showing initials: $initials');
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
