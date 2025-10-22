import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mgi/services/storage_service.dart';
import '../models/building_photo_model.dart';
import '../models/folder_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class BuildingAdminService {
  final ApiService _apiService = ApiService();
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }
  Future<List<BuildingPhotoModel>> getBuildingPhotos(String buildingId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/buildings/$buildingId/photos'),
 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => BuildingPhotoModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load building photos');
      }
    } catch (e) {
      throw Exception('Error loading building photos: $e');
    }
  }

  Future<BuildingPhotoModel> addBuildingPhoto({
    required String buildingId,
    required String photoUrl,
    String? description,
    int order = 0,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/buildings/$buildingId/photos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'photoUrl': photoUrl,
          'description': description,
          'order': order,
        }),
      );

      if (response.statusCode == 200) {
        return BuildingPhotoModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to add building photo');
      }
    } catch (e) {
      throw Exception('Error adding building photo: $e');
    }
  }

  Future<void> deleteBuildingPhoto(int photoId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/buildings/photos/$photoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete building photo');
      }
    } catch (e) {
      throw Exception('Error deleting building photo: $e');
    }
  }

  Future<BuildingPhotoModel> updatePhotoOrder(int photoId, int newOrder) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/buildings/photos/$photoId/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'order': newOrder}),
      );

      if (response.statusCode == 200) {
        return BuildingPhotoModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to update photo order');
      }
    } catch (e) {
      throw Exception('Error updating photo order: $e');
    }
  }

  Future<Map<String, dynamic>> createApartment({
    required String buildingId,
    required String apartmentLabel,
    required String apartmentNumber,
    required int apartmentFloor,
    double? livingAreaSurface,
    int? numberOfRooms,
    int? numberOfBedrooms,
    bool haveBalconyOrTerrace = false,
    bool isFurnished = false,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/apartments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'buildingId': buildingId,
          'apartmentLabel': apartmentLabel,
          'apartmentNumber': apartmentNumber,
          'apartmentFloor': apartmentFloor,
          'livingAreaSurface': livingAreaSurface,
          'numberOfRooms': numberOfRooms,
          'numberOfBedrooms': numberOfBedrooms,
          'haveBalconyOrTerrace': haveBalconyOrTerrace,
          'isFurnished': isFurnished,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to create apartment');
      }
    } catch (e) {
      throw Exception('Error creating apartment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getApartmentsByBuilding(String buildingId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/apartments/building/$buildingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data['content'] ?? []);
      } else {
        throw Exception('Failed to load apartments');
      }
    } catch (e) {
      throw Exception('Error loading apartments: $e');
    }
  }

  Future<Map<String, dynamic>> createBuilding(Map<String, dynamic> buildingData) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/buildings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(buildingData),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to create building: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating building: $e');
    }
  }

  Future<Map<String, dynamic>> getBuildingById(String buildingId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/buildings/$buildingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load building');
      }
    } catch (e) {
      throw Exception('Error loading building: $e');
    }
  }

  Future<Map<String, dynamic>> addResidentToApartment({
    required String fname,
    required String lname,
    required String email,
    String? phoneNumber,
    required String apartmentId,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/admin/add-resident-to-apartment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fname': fname,
          'lname': lname,
          'email': email,
          'phoneNumber': phoneNumber,
          'apartmentId': apartmentId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Failed to add resident');
      }
    } catch (e) {
      throw Exception('Error adding resident: $e');
    }
  }
}
