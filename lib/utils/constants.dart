class Constants {
  // API Configuration
  static const String baseUrl = 'http://109.136.4.153:9090/api/v1'; // Android emulator
  static const String wsUrl = 'ws://109.136.4.153:9090/api/v1/ws';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Message Types
  static const String messageTypeText = 'TEXT';
  static const String messageTypeImage = 'IMAGE';
  static const String messageTypeFile = 'FILE';
  static const String messageTypeAudio = 'AUDIO';
  static const String messageTypeVideo = 'VIDEO';

  // Channel Types
  static const String channelTypeOneToOne = 'ONE_TO_ONE';
  static const String channelTypeGroup = 'GROUP';
  static const String channelTypeBuilding = 'BUILDING';
  static const String channelTypePublic = 'PUBLIC';

  // File Limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxAudioDuration = 300; // 5 minutes

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}