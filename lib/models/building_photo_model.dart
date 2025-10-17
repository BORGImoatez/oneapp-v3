class BuildingPhotoModel {
  final int id;
  final String buildingId;
  final String photoUrl;
  final int photoOrder;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  BuildingPhotoModel({
    required this.id,
    required this.buildingId,
    required this.photoUrl,
    required this.photoOrder,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuildingPhotoModel.fromJson(Map<String, dynamic> json) {
    return BuildingPhotoModel(
      id: json['id'] as int,
      buildingId: json['buildingId'] as String,
      photoUrl: json['photoUrl'] as String,
      photoOrder: json['photoOrder'] as int? ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buildingId': buildingId,
      'photoUrl': photoUrl,
      'photoOrder': photoOrder,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
