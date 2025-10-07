class BuildingMembersModel {
  final List<ResidentSummary> residents;
  final List<ApartmentSummary> apartments;

  BuildingMembersModel({
    required this.residents,
    required this.apartments,
  });

  factory BuildingMembersModel.fromJson(Map<String, dynamic> json) {
    return BuildingMembersModel(
      residents: (json['residents'] as List<dynamic>?)
          ?.map((e) => ResidentSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      apartments: (json['apartments'] as List<dynamic>?)
          ?.map((e) => ApartmentSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class ResidentSummary {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? apartmentId;
  final String? apartmentNumber;
  final String? floor;  // ← AJOUTÉ

  ResidentSummary({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.apartmentId,
    this.apartmentNumber,
    this.floor,  // ← AJOUTÉ
  });

  String get fullName => '$firstName $lastName';

  // ← AJOUTÉ : Propriété pour afficher les infos
  String get displayInfo {
    if (apartmentNumber != null && floor != null) {
      return 'Appt $apartmentNumber - Étage $floor';
    } else if (apartmentNumber != null) {
      return 'Appt $apartmentNumber';
    }
    return 'Aucun appartement';
  }

  factory ResidentSummary.fromJson(Map<String, dynamic> json) {
    return ResidentSummary(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      apartmentId: json['apartmentId'] as String?,
      apartmentNumber: json['apartmentNumber'] as String?,
      floor: json['floor'] as String?,  // ← AJOUTÉ
    );
  }
}


class ApartmentSummary {
  final String id;
  final String apartmentNumber;
  final String? floor;

  ApartmentSummary({
    required this.id,
    required this.apartmentNumber,
    this.floor,
  });

  String get displayName =>
      floor != null ? 'Appt $apartmentNumber (Étage $floor)' : 'Appt $apartmentNumber';

  factory ApartmentSummary.fromJson(Map<String, dynamic> json) {
    return ApartmentSummary(
      id: json['id'] as String,
      apartmentNumber: json['apartmentNumber'] as String,
      floor: json['floor'] as String?,
    );
  }
}
