import 'package:mgi/models/message_model.dart';

class Channel {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String? buildingId;
  final String? buildingGroupId;
  final String createdBy;
  final bool isActive;
  final bool isPrivate;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int memberCount;
  final Message? lastMessage;

  Channel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.buildingId,
    this.buildingGroupId,
    required this.createdBy,
    required this.isActive,
    required this.isPrivate,
    this.isClosed = false,
    required this.createdAt,
    this.updatedAt,
    required this.memberCount,
    this.lastMessage,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      buildingId: json['buildingId'],
      buildingGroupId: json['buildingGroupId'],
      createdBy: json['createdBy'],
      isActive: json['isActive'] ?? true,
      isPrivate: json['isPrivate'] ?? false,
      isClosed: json['isClosed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      memberCount: json['memberCount'] ?? 0,
      lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'buildingId': buildingId,
      'buildingGroupId': buildingGroupId,
      'createdBy': createdBy,
      'isActive': isActive,
      'isPrivate': isPrivate,
      'isClosed': isClosed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'memberCount': memberCount,
      'lastMessage': lastMessage?.toJson(),
    };
  }
}