class SharedMediaModel {
  final int messageId;
  final String mediaUrl;
  final String messageType;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final String messageContent;

  SharedMediaModel({
    required this.messageId,
    required this.mediaUrl,
    required this.messageType,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.messageContent,
  });

  factory SharedMediaModel.fromJson(Map<String, dynamic> json) {
    return SharedMediaModel(
      messageId: json['messageId'],
      mediaUrl: json['mediaUrl'],
      messageType: json['messageType'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      createdAt: DateTime.parse(json['createdAt']),
      messageContent: json['messageContent'],
    );
  }

  bool get isImage => messageType == 'IMAGE';
  bool get isVideo => messageType == 'VIDEO';
  bool get isDocument => messageType == 'FILE';
  bool get isAudio => messageType == 'AUDIO';

  String get fileName {
    try {
      final uri = Uri.parse(mediaUrl);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (e) {
      // Si ce n'est pas une URL, retourner le contenu
    }
    return messageContent;
  }
}
