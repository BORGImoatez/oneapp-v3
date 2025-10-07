import 'folder_permission_model.dart';

class FolderModel {
  final int id;
  final String name;
  final String folderPath;
  final int? parentFolderId;
  final String? apartmentId;
  final String? buildingId;
  final String createdBy;
  final bool isShared;
  final String shareType;
  final DateTime createdAt;
  final int subFolderCount;
  final int documentCount;
  final List<FolderPermissionModel> permissions;
  final bool canRead;
  final bool canUpload;

  FolderModel({
    required this.id,
    required this.name,
    required this.folderPath,
    this.parentFolderId,
    this.apartmentId,
    this.buildingId,
    required this.createdBy,
    this.isShared = false,
    this.shareType = 'PRIVATE',
    required this.createdAt,
    this.subFolderCount = 0,
    this.documentCount = 0,
    this.permissions = const [],
    this.canRead = true,
    this.canUpload = false,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    List<FolderPermissionModel> permissionsList = [];
    if (json['permissions'] != null) {
      permissionsList = (json['permissions'] as List)
          .map((p) => FolderPermissionModel.fromJson(p))
          .toList();
    }

    return FolderModel(
      id: json['id'],
      name: json['name'],
      folderPath: json['folderPath'],
      parentFolderId: json['parentFolderId'],
      apartmentId: json['apartmentId'],
      buildingId: json['buildingId'],
      createdBy: json['createdBy'],
      isShared: json['isShared'] ?? false,
      shareType: json['shareType'] ?? 'PRIVATE',
      createdAt: DateTime.parse(json['createdAt']),
      subFolderCount: json['subFolderCount'] ?? 0,
      documentCount: json['documentCount'] ?? 0,
      permissions: permissionsList,
      canRead: json['canRead'] ?? true,
      canUpload: json['canUpload'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'folderPath': folderPath,
      'parentFolderId': parentFolderId,
      'apartmentId': apartmentId,
      'buildingId': buildingId,
      'createdBy': createdBy,
      'isShared': isShared,
      'shareType': shareType,
      'createdAt': createdAt.toIso8601String(),
      'subFolderCount': subFolderCount,
      'documentCount': documentCount,
      'permissions': permissions.map((p) => p.toJson()).toList(),
      'canRead': canRead,
      'canUpload': canUpload,
    };
  }
}
