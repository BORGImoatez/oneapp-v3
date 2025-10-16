class FileAttachment {
  final int id;
  final String originalFilename;
  final String storedFilename;
  final String filePath;
  final String downloadUrl;
  final int fileSize;
  final String mimeType;
  final String fileType;
  final String uploadedBy;
  final int? duration;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final DateTime createdAt;

  FileAttachment({
    required this.id,
    required this.originalFilename,
    required this.storedFilename,
    required this.filePath,
    required this.downloadUrl,
    required this.fileSize,
    required this.mimeType,
    required this.fileType,
    required this.uploadedBy,
    this.duration,
    this.thumbnailPath,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'],
      originalFilename: json['originalFilename'],
      storedFilename: json['storedFilename'],
      filePath: json['filePath'],
      downloadUrl: json['downloadUrl'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      fileType: json['fileType'],
      uploadedBy: json['uploadedBy'],
      duration: json['duration'],
      thumbnailPath: json['thumbnailPath'],
      thumbnailUrl: json['thumbnailUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalFilename': originalFilename,
      'storedFilename': storedFilename,
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'duration': duration,
      'thumbnailPath': thumbnailPath,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Message {
  final int id;
  final int channelId;
  final String senderId;
  final String senderFname;
  final String senderLname;
  final String? senderPicture;
  final String content;
  final String type;
  final int? replyToId;
  final FileAttachment? fileAttachment;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderFname,
    required this.senderLname,
    this.senderPicture,
    required this.content,
    required this.type,
    this.replyToId,
    this.fileAttachment,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      channelId: json['channelId'],
      senderId: json['senderId'],
      senderFname: json['senderFname'] ?? '',
      senderLname: json['senderLname'] ?? '',
      senderPicture: json['senderPicture'],
      content: json['content'],
      type: json['type'],
      replyToId: json['replyToId'],
      fileAttachment: json['fileAttachment'] != null
          ? FileAttachment.fromJson(json['fileAttachment'])
          : null,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'senderId': senderId,
      'senderFname': senderFname,
      'senderLname': senderLname,
      'senderPicture': senderPicture,
      'content': content,
      'type': type,
      'replyToId': replyToId,
      'fileAttachment': fileAttachment?.toJson(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}