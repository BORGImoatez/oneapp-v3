class FolderPermissionModel {
  final int id;
  final String? apartmentId;
  final String? residentId;
  final bool canRead;
  final bool canUpload;

  FolderPermissionModel({
    required this.id,
    this.apartmentId,
    this.residentId,
    this.canRead = true,
    this.canUpload = false,
  });

  factory FolderPermissionModel.fromJson(Map<String, dynamic> json) {
    return FolderPermissionModel(
      id: json['id'],
      apartmentId: json['apartmentId'],
      residentId: json['residentId'],
      canRead: json['canRead'] ?? true,
      canUpload: json['canUpload'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'residentId': residentId,
      'canRead': canRead,
      'canUpload': canUpload,
    };
  }
}
