import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/claim_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ClaimService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<ClaimModel> createClaim({
    required int apartmentId,
    required List<String> claimTypes,
    required String cause,
    required String description,
    String? insuranceCompany,
    String? insurancePolicyNumber,
    List<int>? affectedApartmentIds,
    List<File>? photos,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final claimData = {
        'apartmentId': apartmentId,
        'claimTypes': claimTypes,
        'cause': cause,
        'description': description,
        'insuranceCompany': insuranceCompany,
        'insurancePolicyNumber': insurancePolicyNumber,
        'affectedApartmentIds': affectedApartmentIds ?? [],
      };

      final uri = Uri.parse('${_apiService.baseUrl}/api/claims');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['claimData'] = jsonEncode(claimData);

      if (photos != null && photos.isNotEmpty) {
        for (var photo in photos) {
          var stream = http.ByteStream(photo.openRead());
          var length = await photo.length();
          var multipartFile = http.MultipartFile(
            'photos',
            stream,
            length,
            filename: photo.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ClaimModel.fromJson(data);
      } else {
        throw Exception('Failed to create claim: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating claim: $e');
    }
  }

  Future<List<ClaimModel>> getClaimsByBuilding(int buildingId) async {
    try {
      final response = await _apiService.get('/api/claims/building/$buildingId');
      final List<dynamic> data = response;
      return data.map((json) => ClaimModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching claims: $e');
    }
  }

  Future<ClaimModel> getClaimById(int claimId) async {
    try {
      final response = await _apiService.get('/api/claims/$claimId');
      return ClaimModel.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching claim: $e');
    }
  }

  Future<ClaimModel> updateClaimStatus(int claimId, String status) async {
    try {
      final response = await _apiService.patch(
        '/api/claims/$claimId/status',
        {'status': status},
      );
      return ClaimModel.fromJson(response);
    } catch (e) {
      throw Exception('Error updating claim status: $e');
    }
  }

  Future<void> deleteClaim(int claimId) async {
    try {
      await _apiService.delete('/api/claims/$claimId');
    } catch (e) {
      throw Exception('Error deleting claim: $e');
    }
  }
}
