import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/claim_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ClaimService {
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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
      final token = await _getToken();
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

      final uri = Uri.parse('${Constants.baseUrl}/api/claims');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['claimData'] = jsonEncode(claimData);

      if (photos != null && photos.isNotEmpty) {
        for (var photo in photos) {
          request.files.add(
            await http.MultipartFile.fromPath('photos', photo.path),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ClaimModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create claim');
      }
    } catch (e) {
      throw Exception('Error creating claim: $e');
    }
  }

  Future<List<ClaimModel>> getClaimsByBuilding(int buildingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/claims/building/$buildingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ClaimModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load claims');
      }
    } catch (e) {
      throw Exception('Error fetching claims: $e');
    }
  }

  Future<ClaimModel> getClaimById(int claimId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/claims/$claimId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ClaimModel.fromJson(data);
      } else {
        throw Exception('Failed to load claim');
      }
    } catch (e) {
      throw Exception('Error fetching claim: $e');
    }
  }

  Future<ClaimModel> updateClaimStatus(int claimId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${Constants.baseUrl}/api/claims/$claimId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ClaimModel.fromJson(data);
      } else {
        throw Exception('Failed to update claim status');
      }
    } catch (e) {
      throw Exception('Error updating claim status: $e');
    }
  }

  Future<void> deleteClaim(int claimId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/api/claims/$claimId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete claim');
      }
    } catch (e) {
      throw Exception('Error deleting claim: $e');
    }
  }
}
