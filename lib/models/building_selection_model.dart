class BuildingSelection {
  final String buildingId;
  final String buildingLabel;
  final String? buildingNumber;
  final String? buildingPicture;
  final String roleInBuilding;
  final String? apartmentId;
  final String? apartmentLabel;
  final String? apartmentNumber;
  final int? apartmentFloor;
  final Address? address;

  BuildingSelection({
    required this.buildingId,
    required this.buildingLabel,
    this.buildingNumber,
    this.buildingPicture,
    required this.roleInBuilding,
    this.apartmentId,
    this.apartmentLabel,
    this.apartmentNumber,
    this.apartmentFloor,
    this.address,
  });

  factory BuildingSelection.fromJson(Map<String, dynamic> json) {
    return BuildingSelection(
      buildingId: json['buildingId'],
      buildingLabel: json['buildingLabel'],
      buildingNumber: json['buildingNumber'],
      buildingPicture: json['buildingPicture'],
      roleInBuilding: json['roleInBuilding'],
      apartmentId: json['apartmentId'],
      apartmentLabel: json['apartmentLabel'],
      apartmentNumber: json['apartmentNumber'],
      apartmentFloor: json['apartmentFloor'],
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buildingId': buildingId,
      'buildingLabel': buildingLabel,
      'buildingNumber': buildingNumber,
      'buildingPicture': buildingPicture,
      'roleInBuilding': roleInBuilding,
      'apartmentId': apartmentId,
      'apartmentLabel': apartmentLabel,
      'apartmentNumber': apartmentNumber,
      'apartmentFloor': apartmentFloor,
      'address': address?.toJson(),
    };
  }
}

class Address {
  final int? idAddress;
  final String address;
  final String? addressSuite;
  final String codePostal;
  final String ville;
  final String? etatDep;
  final String? observation;

  Address({
    this.idAddress,
    required this.address,
    this.addressSuite,
    required this.codePostal,
    required this.ville,
    this.etatDep,
    this.observation,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      idAddress: json['idAddress'],
      address: json['address'],
      addressSuite: json['addressSuite'],
      codePostal: json['codePostal'],
      ville: json['ville'],
      etatDep: json['etatDep'],
      observation: json['observation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idAddress': idAddress,
      'address': address,
      'addressSuite': addressSuite,
      'codePostal': codePostal,
      'ville': ville,
      'etatDep': etatDep,
      'observation': observation,
    };
  }
}