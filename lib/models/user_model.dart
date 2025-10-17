class User {
  final String id;
  final String fname;
  final String lname;
  final String email;
  final String? phoneNumber;
  final String? picture;
  final String role;
  final String accountStatus;
  final String? buildingId;
  final String? apartmentId;
  final String? roleInBuilding;

  User({
    required this.id,
    required this.fname,
    required this.lname,
    required this.email,
    this.phoneNumber,
    this.picture,
    required this.role,
    required this.accountStatus,
    this.buildingId,
    this.apartmentId,
    this.roleInBuilding,
  });

  String get fullName => '$fname $lname';
  String get initials => '${fname[0]}${lname[0]}'.toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] ?? json['idUsers'] ?? '';
    print('DEBUG: Creating user with ID: $userId from JSON: $json'); // Debug log
    return User(
      id: userId,
      fname: json['fname'] ?? '',
      lname: json['lname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      picture: json['picture'],
      role: json['role'] ?? 'RESIDENT',
      accountStatus: json['accountStatus'] ?? 'ACTIVE',
      buildingId: json['buildingId'],
      apartmentId: json['apartmentId'],
      roleInBuilding: json['roleInBuilding'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'fname': fname,
      'lname': lname,
      'email': email,
      'phoneNumber': phoneNumber,
      'picture': picture,
      'role': role,
      'accountStatus': accountStatus,
      'buildingId': buildingId,
      'apartmentId': apartmentId,
      'roleInBuilding': roleInBuilding,
    };
  }

  bool get isBuildingAdmin => roleInBuilding == 'BUILDING_ADMIN';
  bool get isGroupAdmin => roleInBuilding == 'GROUP_ADMIN';
  bool get isSuperAdmin => roleInBuilding == 'SUPER_ADMIN';
  bool get isAdmin => isBuildingAdmin || isGroupAdmin || isSuperAdmin;
}