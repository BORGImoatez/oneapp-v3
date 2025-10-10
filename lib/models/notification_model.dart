class NotificationModel {
  final int id;
  final String residentId;
  final String buildingId;
  final String title;
  final String body;
  final String type;
  final int? channelId;
  final int? voteId;
  final int? documentId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.residentId,
    required this.buildingId,
    required this.title,
    required this.body,
    required this.type,
    this.channelId,
    this.voteId,
    this.documentId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      residentId: json['residentId'] as String,
      buildingId: json['buildingId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      channelId: json['channelId'] as int?,
      voteId: json['voteId'] as int?,
      documentId: json['documentId'] as int?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residentId': residentId,
      'buildingId': buildingId,
      'title': title,
      'body': body,
      'type': type,
      'channelId': channelId,
      'voteId': voteId,
      'documentId': documentId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
