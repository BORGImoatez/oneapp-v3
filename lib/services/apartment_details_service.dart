import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mgi/services/storage_service.dart';
import 'dart:convert';
import '../models/apartment_details_model.dart';
import '../utils/constants.dart';

class ApartmentDetailsService {
  final String baseUrl = '${Constants.baseUrl}/api/apartments';
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }
  Future<ApartmentDetailsModel> getApartmentDetails(
      String apartmentId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/$apartmentId/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentDetailsModel.fromJson(data);
      } else {
        throw Exception('Failed to load apartment details');
      }
    } catch (e) {
      throw Exception('Error loading apartment details: $e');
    }
  }

  Future<ApartmentDetailsModel> updateApartmentDetails(
      String apartmentId,
      Map<String, dynamic> updates,
      ) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/$apartmentId/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentDetailsModel.fromJson(data);
      } else {
        throw Exception('Failed to update apartment details');
      }
    } catch (e) {
      throw Exception('Error updating apartment details: $e');
    }
  }

  Future<ApartmentPhotoModel> uploadPhoto(
      String apartmentId,
      File imageFile,
      ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$apartmentId/details/photos'),
      );
      final token = await _getToken();

      request.headers['Authorization'] = 'Bearer $token';

      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      final mimeType = _getMimeType(imageFile.path);

      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentPhotoModel.fromJson(data);
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ Upload photo failed: ${response.statusCode}');
        print('➡️ Response body: $errorBody');
        throw Exception('Failed to upload photo: $response');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
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
  Future<void> deletePhoto(int photoId) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/0/details/photos/$photoId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete photo');
      }
    } catch (e) {
      throw Exception('Error deleting photo: $e');
    }
  }

  Future<void> reorderPhotos(
      int apartmentId,
      List<int> photoIds,
      ) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$apartmentId/details/photos/reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(photoIds),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reorder photos');
      }
    } catch (e) {
      throw Exception('Error reordering photos: $e');
    }
  }

  Future<List<SimpleApartment>> getApartmentsByBuilding(String buildingId) async {
    try {
      final token = await _getToken();
      final url = '${Constants.baseUrl}/api/apartments/building/$buildingId';
      print('🔍 Fetching apartments from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('📋 Parsed data keys: ${data.keys}');
        final List<dynamic> apartments = data['content'] ?? [];
        print('🏢 Number of apartments found: ${apartments.length}');

        if (apartments.isNotEmpty) {
          print('🔎 First apartment data: ${apartments[0]}');
        }

        return apartments.map((apt) => SimpleApartment.fromJson(apt)).toList();
      } else {
        throw Exception('Failed to load apartments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading apartments: $e');
      throw Exception('Error loading apartments: $e');
    }
  }

  Future<SimpleApartment?> getCurrentUserApartment(String buildingId) async {
    try {
      final token = await _getToken();
      final url = '${Constants.baseUrl}/api/apartments/current?buildingId=$buildingId';
      print('👤 Fetching current user apartment from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 User apartment response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('🏠 User apartment data: $data');
        return SimpleApartment.fromJson(data);
      } else if (response.statusCode == 404) {
        print('⚠️ No apartment found for current user');
        return null;
      } else {
        print('❌ Failed to load user apartment: ${response.statusCode}');
        throw Exception('Failed to load user apartment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting user apartment: $e');
      throw Exception('Error getting user apartment: $e');
    }
  }
}

class SimpleApartment {
  final String id;
  final String apartmentNumber;
  final int? floor;

  SimpleApartment({
    required this.id,
    required this.apartmentNumber,
    this.floor,
  });

  factory SimpleApartment.fromJson(Map<String, dynamic> json) {
    print('🔧 Parsing apartment: $json');

    return SimpleApartment(
      id: json['id'] ?? json['idApartment'] ?? '',
      apartmentNumber: json['apartmentNumber'] ?? '',
      floor: json['floor'] ?? json['apartmentFloor'],
    );
  }
}
