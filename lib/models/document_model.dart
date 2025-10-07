class DocumentModel {
  final int id;
  final String originalFilename;
  final String storedFilename;
  final String filePath;
  final int fileSize;
  final String? mimeType;
  final String? fileExtension;
  final int folderId;
  final String? apartmentId;
  final String? buildingId;
  final String uploadedBy;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? downloadUrl;
  final String? previewUrl;

  DocumentModel({
    required this.id,
    required this.originalFilename,
    required this.storedFilename,
    required this.filePath,
    required this.fileSize,
    this.mimeType,
    this.fileExtension,
    required this.folderId,
    this.apartmentId,
    this.buildingId,
    required this.uploadedBy,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.downloadUrl,
    this.previewUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      originalFilename: json['originalFilename'],
      storedFilename: json['storedFilename'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      fileExtension: json['fileExtension'],
      folderId: json['folderId'],
      apartmentId: json['apartmentId'],
      buildingId: json['buildingId'],
      uploadedBy: json['uploadedBy'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      downloadUrl: json['downloadUrl'],
      previewUrl: json['previewUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalFilename': originalFilename,
      'storedFilename': storedFilename,
      'filePath': filePath,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      'folderId': folderId,
      'apartmentId': apartmentId,
      'buildingId': buildingId,
      'uploadedBy': uploadedBy,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'downloadUrl': downloadUrl,
      'previewUrl': previewUrl,
    };
  }

  String getFormattedSize() {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  bool get isImage => mimeType?.startsWith('image/') ?? false;
  bool get isPdf => mimeType == 'application/pdf';
  bool get isDocument => mimeType?.contains('document') ?? false ||
                         mimeType!.contains('word') ?? false ||
                         mimeType!.contains('text') ?? false;
}
