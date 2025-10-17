import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ProfileService {
  final String baseUrl = '${Constants.baseUrl}/profile';

  Future<User> getCurrentProfile(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<User> updateProfile({
    required String token,
    String? fname,
    String? lname,
    String? email,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (fname != null) body['fname'] = fname;
    if (lname != null) body['lname'] = lname;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    final response = await http.put(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  Future<User> uploadProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/picture'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final mimeType = _getMimeType(imageFile.path);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('DEBUG ProfileService: Upload status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      print('DEBUG ProfileService: Upload response: $data');
      final user = User.fromJson(data);
      print('DEBUG ProfileService: Parsed user picture: ${user.picture}');
      return user;
    } else {
      print('DEBUG ProfileService: Upload failed: ${response.body}');
      throw Exception('Failed to upload profile picture: ${response.statusCode}');
    }
  }

  Future<void> deleteProfilePicture(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/picture'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete profile picture: ${response.statusCode}');
    }
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw Exception('Mot de passe actuel incorrect');
      }
      throw Exception('Failed to change password: ${response.statusCode}');
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
