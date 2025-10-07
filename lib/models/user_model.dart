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
    };
  }
}