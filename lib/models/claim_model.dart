class ClaimModel {
  final int id;
  final int apartmentId;
  final String apartmentNumber;
  final int buildingId;
  final String buildingName;
  final int reporterId;
  final String reporterName;
  final String? reporterAvatar;
  final List<String> claimTypes;
  final String cause;
  final String description;
  final String? insuranceCompany;
  final String? insurancePolicyNumber;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> affectedApartmentIds;
  final List<ClaimPhotoModel> photos;

  ClaimModel({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.buildingId,
    required this.buildingName,
    required this.reporterId,
    required this.reporterName,
    this.reporterAvatar,
    required this.claimTypes,
    required this.cause,
    required this.description,
    this.insuranceCompany,
    this.insurancePolicyNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.affectedApartmentIds,
    required this.photos,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'],
      apartmentId: json['apartmentId'],
      apartmentNumber: json['apartmentNumber'],
      buildingId: json['buildingId'],
      buildingName: json['buildingName'],
      reporterId: json['reporterId'],
      reporterName: json['reporterName'],
      reporterAvatar: json['reporterAvatar'],
      claimTypes: List<String>.from(json['claimTypes'] ?? []),
      cause: json['cause'],
      description: json['description'],
      insuranceCompany: json['insuranceCompany'],
      insurancePolicyNumber: json['insurancePolicyNumber'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      affectedApartmentIds: List<int>.from(json['affectedApartmentIds'] ?? []),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((p) => ClaimPhotoModel.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'apartmentNumber': apartmentNumber,
      'buildingId': buildingId,
      'buildingName': buildingName,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterAvatar': reporterAvatar,
      'claimTypes': claimTypes,
      'cause': cause,
      'description': description,
      'insuranceCompany': insuranceCompany,
      'insurancePolicyNumber': insurancePolicyNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'affectedApartmentIds': affectedApartmentIds,
      'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'IN_PROGRESS':
        return 'En cours';
      case 'RESOLVED':
        return 'Résolu';
      case 'CLOSED':
        return 'Fermé';
      default:
        return status;
    }
  }
}

class ClaimPhotoModel {
  final int id;
  final String photoUrl;
  final int photoOrder;
  final DateTime createdAt;

  ClaimPhotoModel({
    required this.id,
    required this.photoUrl,
    required this.photoOrder,
    required this.createdAt,
  });

  factory ClaimPhotoModel.fromJson(Map<String, dynamic> json) {
    return ClaimPhotoModel(
      id: json['id'],
      photoUrl: json['photoUrl'],
      photoOrder: json['photoOrder'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoUrl': photoUrl,
      'photoOrder': photoOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum ClaimType {
  incendie('INCENDIE', 'Incendie'),
  vol('VOL', 'Vol'),
  degatsDesEaux('DEGATS_DES_EAUX', 'Dégâts des eaux'),
  degatNaturel('DEGAT_NATUREL', 'Dégât naturel (orage, ...)'),
  contamination('CONTAMINATION', 'Contamination (champignons, nuisibles)'),
  brisDePortes('BRIS_DE_PORTES', 'Bris de porte(s)'),
  brisDeVitres('BRIS_DE_VITRES', 'Bris de vitre(s)'),
  autre('AUTRE', 'Autre');

  final String value;
  final String displayName;

  const ClaimType(this.value, this.displayName);

  static ClaimType fromValue(String value) {
    return ClaimType.values.firstWhere((type) => type.value == value);
  }
}

enum ClaimStatus {
  pending('PENDING', 'En attente'),
  inProgress('IN_PROGRESS', 'En cours'),
  resolved('RESOLVED', 'Résolu'),
  closed('CLOSED', 'Fermé');

  final String value;
  final String displayName;

  const ClaimStatus(this.value, this.displayName);

  static ClaimStatus fromValue(String value) {
    return ClaimStatus.values.firstWhere((status) => status.value == value);
  }
}
