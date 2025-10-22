class ApartmentDetailsModel {
  final String apartmentId;
  final String apartmentNumber;
  final List<ApartmentPhotoModel> photos;
  final GeneralInfoModel? generalInfo;
  final InteriorModel? interior;
  final ExteriorModel? exterior;
  final InstallationsModel? installations;
  final EnergieModel? energie;

  ApartmentDetailsModel({
    required this.apartmentId,
    required this.apartmentNumber,
    required this.photos,
    this.generalInfo,
    this.interior,
    this.exterior,
    this.installations,
    this.energie,
  });

  factory ApartmentDetailsModel.fromJson(Map<String, dynamic> json) {
    return ApartmentDetailsModel(
      apartmentId: json['apartmentId'],
      apartmentNumber: json['apartmentNumber'],
      photos: (json['photos'] as List?)
              ?.map((p) => ApartmentPhotoModel.fromJson(p))
              .toList() ??
          [],
      generalInfo: json['generalInfo'] != null
          ? GeneralInfoModel.fromJson(json['generalInfo'])
          : null,
      interior: json['interior'] != null
          ? InteriorModel.fromJson(json['interior'])
          : null,
      exterior: json['exterior'] != null
          ? ExteriorModel.fromJson(json['exterior'])
          : null,
      installations: json['installations'] != null
          ? InstallationsModel.fromJson(json['installations'])
          : null,
      energie: json['energie'] != null
          ? EnergieModel.fromJson(json['energie'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apartmentId': apartmentId,
      'apartmentNumber': apartmentNumber,
      'photos': photos.map((p) => p.toJson()).toList(),
      'generalInfo': generalInfo?.toJson(),
      'interior': interior?.toJson(),
      'exterior': exterior?.toJson(),
      'installations': installations?.toJson(),
      'energie': energie?.toJson(),
    };
  }
}

class ApartmentPhotoModel {
  final int id;
  final String apartmentId;
  final String photoUrl;
  final int displayOrder;
  final DateTime uploadedAt;
  final String? uploadedBy;

  ApartmentPhotoModel({
    required this.id,
    required this.apartmentId,
    required this.photoUrl,
    required this.displayOrder,
    required this.uploadedAt,
    this.uploadedBy,
  });

  factory ApartmentPhotoModel.fromJson(Map<String, dynamic> json) {
    return ApartmentPhotoModel(
      id: json['id'],
      apartmentId: json['apartmentId'],
      photoUrl: json['photoUrl'],
      displayOrder: json['displayOrder'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt']),
      uploadedBy: json['uploadedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'photoUrl': photoUrl,
      'displayOrder': displayOrder,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }
}

class GeneralInfoModel {
  final int? id;
  final int? nbChambres;
  final int? nbSalleBain;
  final double? surface;
  final int? etage;
  final DateTime? updatedAt;

  GeneralInfoModel({
    this.id,
    this.nbChambres,
    this.nbSalleBain,
    this.surface,
    this.etage,
    this.updatedAt,
  });

  factory GeneralInfoModel.fromJson(Map<String, dynamic> json) {
    return GeneralInfoModel(
      id: json['id'],
      nbChambres: json['nbChambres'],
      nbSalleBain: json['nbSalleBain'],
      surface: json['surface']?.toDouble(),
      etage: json['etage'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nbChambres': nbChambres,
      'nbSalleBain': nbSalleBain,
      'surface': surface,
      'etage': etage,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class InteriorModel {
  final int? id;
  final String? quartierLieu;
  final double? surfaceHabitable;
  final double? surfaceSalon;
  final String? typeCuisine;
  final double? surfaceCuisine;
  final List<double>? surfaceChambres;
  final int? nbSalleDouche;
  final int? nbToilette;
  final bool? cave;
  final bool? grenier;
  final DateTime? updatedAt;

  InteriorModel({
    this.id,
    this.quartierLieu,
    this.surfaceHabitable,
    this.surfaceSalon,
    this.typeCuisine,
    this.surfaceCuisine,
    this.surfaceChambres,
    this.nbSalleDouche,
    this.nbToilette,
    this.cave,
    this.grenier,
    this.updatedAt,
  });

  factory InteriorModel.fromJson(Map<String, dynamic> json) {
    return InteriorModel(
      id: json['id'],
      quartierLieu: json['quartierLieu'],
      surfaceHabitable: json['surfaceHabitable']?.toDouble(),
      surfaceSalon: json['surfaceSalon']?.toDouble(),
      typeCuisine: json['typeCuisine'],
      surfaceCuisine: json['surfaceCuisine']?.toDouble(),
      surfaceChambres: (json['surfaceChambres'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      nbSalleDouche: json['nbSalleDouche'],
      nbToilette: json['nbToilette'],
      cave: json['cave'],
      grenier: json['grenier'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quartierLieu': quartierLieu,
      'surfaceHabitable': surfaceHabitable,
      'surfaceSalon': surfaceSalon,
      'typeCuisine': typeCuisine,
      'surfaceCuisine': surfaceCuisine,
      'surfaceChambres': surfaceChambres,
      'nbSalleDouche': nbSalleDouche,
      'nbToilette': nbToilette,
      'cave': cave,
      'grenier': grenier,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class ExteriorModel {
  final int? id;
  final double? surfaceTerrasse;
  final String? orientationTerrasse;
  final DateTime? updatedAt;

  ExteriorModel({
    this.id,
    this.surfaceTerrasse,
    this.orientationTerrasse,
    this.updatedAt,
  });

  factory ExteriorModel.fromJson(Map<String, dynamic> json) {
    return ExteriorModel(
      id: json['id'],
      surfaceTerrasse: json['surfaceTerrasse']?.toDouble(),
      orientationTerrasse: json['orientationTerrasse'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surfaceTerrasse': surfaceTerrasse,
      'orientationTerrasse': orientationTerrasse,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class InstallationsModel {
  final int? id;
  final bool? ascenseur;
  final bool? accesHandicap;
  final bool? parlophone;
  final bool? interphoneVideo;
  final bool? porteBlindee;
  final bool? piscine;
  final DateTime? updatedAt;

  InstallationsModel({
    this.id,
    this.ascenseur,
    this.accesHandicap,
    this.parlophone,
    this.interphoneVideo,
    this.porteBlindee,
    this.piscine,
    this.updatedAt,
  });

  factory InstallationsModel.fromJson(Map<String, dynamic> json) {
    return InstallationsModel(
      id: json['id'],
      ascenseur: json['ascenseur'],
      accesHandicap: json['accesHandicap'],
      parlophone: json['parlophone'],
      interphoneVideo: json['interphoneVideo'],
      porteBlindee: json['porteBlindee'],
      piscine: json['piscine'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ascenseur': ascenseur,
      'accesHandicap': accesHandicap,
      'parlophone': parlophone,
      'interphoneVideo': interphoneVideo,
      'porteBlindee': porteBlindee,
      'piscine': piscine,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class EnergieModel {
  final int? id;
  final String? classeEnergetique;
  final double? consommationEnergiePrimaire;
  final double? consommationTheoriqueTotale;
  final double? emissionCo2;
  final String? numeroRapportPeb;
  final String? typeChauffage;
  final bool? doubleVitrage;
  final DateTime? updatedAt;

  EnergieModel({
    this.id,
    this.classeEnergetique,
    this.consommationEnergiePrimaire,
    this.consommationTheoriqueTotale,
    this.emissionCo2,
    this.numeroRapportPeb,
    this.typeChauffage,
    this.doubleVitrage,
    this.updatedAt,
  });

  factory EnergieModel.fromJson(Map<String, dynamic> json) {
    return EnergieModel(
      id: json['id'],
      classeEnergetique: json['classeEnergetique'],
      consommationEnergiePrimaire:
          json['consommationEnergiePrimaire']?.toDouble(),
      consommationTheoriqueTotale:
          json['consommationTheoriqueTotale']?.toDouble(),
      emissionCo2: json['emissionCo2']?.toDouble(),
      numeroRapportPeb: json['numeroRapportPeb'],
      typeChauffage: json['typeChauffage'],
      doubleVitrage: json['doubleVitrage'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classeEnergetique': classeEnergetique,
      'consommationEnergiePrimaire': consommationEnergiePrimaire,
      'consommationTheoriqueTotale': consommationTheoriqueTotale,
      'emissionCo2': emissionCo2,
      'numeroRapportPeb': numeroRapportPeb,
      'typeChauffage': typeChauffage,
      'doubleVitrage': doubleVitrage,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
