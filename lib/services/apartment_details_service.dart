import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../models/apartment_details_model.dart';
import '../utils/constants.dart';

class ApartmentDetailsService {
  final String baseUrl = '${Constants.baseUrl}/api/apartments';

  Future<ApartmentDetailsModel> getApartmentDetails(
      int apartmentId, String token) async {
    try {
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
    int apartmentId,
    String token,
    Map<String, dynamic> updates,
  ) async {
    try {
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
    int apartmentId,
    String token,
    File imageFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$apartmentId/details/photos'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentPhotoModel.fromJson(data);
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  Future<void> deletePhoto(int photoId, String token) async {
    try {
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
    String token,
    List<int> photoIds,
  ) async {
    try {
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
}
