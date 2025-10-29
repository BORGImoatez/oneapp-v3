class CallModel {
  final int? id;
  final int channelId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String status;
  final DateTime createdAt;

  CallModel({
    this.id,
    required this.channelId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.status,
    required this.createdAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'],
      channelId: json['channelId'],
      callerId: json['callerId'],
      callerName: json['callerName'],
      callerAvatar: json['callerAvatar'],
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      receiverAvatar: json['receiverAvatar'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      durationSeconds: json['durationSeconds'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String getFormattedDuration() {
    if (durationSeconds == null) return '0:00';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
