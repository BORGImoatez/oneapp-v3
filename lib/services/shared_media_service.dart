import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shared_media_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class SharedMediaService {
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

  Future<List<SharedMediaModel>> getSharedMedia(int channelId, {String? type, int page = 0, int size = 50}) async {
    try {
      final headers = await _getHeaders();
      String url = '${Constants.baseUrl}/messages/channel/$channelId/media?page=$page&size=$size';

      if (type != null && type.isNotEmpty) {
        url += '&type=$type';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> content = data['content'];
        return content.map((json) => SharedMediaModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shared media');
      }
    } catch (e) {
      throw Exception('Error loading shared media: $e');
    }
  }

  Future<List<SharedMediaModel>> getSharedImages(int channelId, {int page = 0, int size = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/messages/channel/$channelId/media/images?page=$page&size=$size'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> content = data['content'];
        return content.map((json) => SharedMediaModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shared images');
      }
    } catch (e) {
      throw Exception('Error loading shared images: $e');
    }
  }

  Future<List<SharedMediaModel>> getSharedVideos(int channelId, {int page = 0, int size = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/messages/channel/$channelId/media/videos?page=$page&size=$size'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> content = data['content'];
        return content.map((json) => SharedMediaModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shared videos');
      }
    } catch (e) {
      throw Exception('Error loading shared videos: $e');
    }
  }

  Future<List<SharedMediaModel>> getSharedDocuments(int channelId, {int page = 0, int size = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/messages/channel/$channelId/media/documents?page=$page&size=$size'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> content = data['content'];
        return content.map((json) => SharedMediaModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shared documents');
      }
    } catch (e) {
      throw Exception('Error loading shared documents: $e');
    }
  }
}
