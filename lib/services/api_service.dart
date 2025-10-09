import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = Constants.baseUrl;

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyLogin(String email, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-login'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'email': email,
        'otpCode': otpCode,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode(userData),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyRegistration(String email, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-registration'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'email': email,
        'otpCode': otpCode,
      }),
    );

    return _handleResponse(response);
  }

  Future<List<dynamic>> getUserBuildings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/user-buildings'),
      headers: await _getHeaders(),
    );

    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> selectBuilding(String buildingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/select-building'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'buildingId': buildingId,
      }),
    );

    return _handleResponse(response);
  }

  Future<void> updateFcmToken(String fcmToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/update-fcm-token'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'fcmToken': fcmToken,
      }),
    );

    _handleVoidResponse(response);
  }

  // Channel endpoints
  Future<Map<String, dynamic>> getChannels({int page = 0, int size = 20}) async {
    final token = await StorageService.getToken();
    print('DEBUG: API - Getting channels for current building context with token: ${token?.substring(0, 20)}...');

    final response = await http.get(
      Uri.parse('$baseUrl/channels?page=$page&size=$size'),
      headers: await _getHeaders(),
    );

    print('DEBUG: API - Channels response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('DEBUG: API - Channels response body: ${response.body}');
    }
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getChannel(int channelId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/channels/$channelId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createChannel(Map<String, dynamic> channelData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/channels'),
      headers: await _getHeaders(),
      body: jsonEncode(channelData),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getOrCreateDirectChannel(String otherUserId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/channels/direct/$otherUserId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Message endpoints
  Future<Map<String, dynamic>> getChannelMessages(int channelId, {int page = 0, int size = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/channel/$channelId?page=$page&size=$size'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> messageData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: await _getHeaders(),
      body: jsonEncode(messageData),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> editMessage(int messageId, String content) async {
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$messageId?content=${Uri.encodeComponent(content)}'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<void> deleteMessage(int messageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: await _getHeaders(),
    );

    _handleVoidResponse(response);
  }

  // Vote endpoints
  Future<Map<String, dynamic>> createVote(Map<String, dynamic> voteData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/votes'),
      headers: await _getHeaders(),
      body: jsonEncode(voteData),
    );

    return _handleResponse(response);
  }

  Future<void> submitVote(Map<String, dynamic> voteData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/votes/submit'),
      headers: await _getHeaders(),
      body: jsonEncode(voteData),
    );

    _handleVoidResponse(response);
  }

  Future<List<dynamic>> getChannelVotes(int channelId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/votes/channel/$channelId'),
      headers: await _getHeaders(),
    );

    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> getVote(int voteId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/votes/$voteId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> closeVote(int voteId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/votes/$voteId/close'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  // Channel member management
  Future<Map<String, dynamic>> addMemberToChannel(int channelId, String memberId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/channels/$channelId/members/$memberId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<void> removeMemberFromChannel(int channelId, String memberId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/channels/$channelId/members/$memberId'),
      headers: await _getHeaders(),
    );

    _handleVoidResponse(response);
  }

  // Residents endpoints
  Future<List<dynamic>> getBuildingResidents(String buildingId) async {
    final token = await StorageService.getToken();
    print('DEBUG: Making API call to get building residents for: $buildingId with token: ${token?.substring(0, 20)}...');
  print(buildingId);
    // Si buildingId est "current", utiliser l'endpoint spécial
    final endpoint = buildingId == "current"
        ? '$baseUrl/channels/current-building/residents'
        : '$baseUrl/channels/building/$buildingId/residents';

    print('DEBUG: Using endpoint: $endpoint');
    final response = await http.get(
      Uri.parse(endpoint),
      headers: await _getHeaders(),
    );

    print('DEBUG: Building residents API response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('DEBUG: Building residents API response body: ${response.body}');
    }

    return _handleListResponse(response);
  }

  // File upload
  Future<Map<String, dynamic>> uploadFile(File file, String type) async {
    try {
      final uri = Uri.parse('$baseUrl/files/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add file
      final mimeType = lookupMimeType(file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);

      // Add type parameter
      request.fields['type'] = type;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException(message: 'Failed to upload file: $e', statusCode: 500);
    }
  }
// 🔥 version spécifique pour les réponses "List"
  List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      } else {
        throw Exception('Expected List but got ${decoded.runtimeType}');
      }
    } else {
      throw Exception('Failed request: ${response.statusCode} - ${response.body}');
    }
  }
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Une erreur est survenue',
        statusCode: response.statusCode,
      );
    }
  }

  void _handleVoidResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success - no need to parse response body for void endpoints
      return;
    } else {
      // Try to parse error message if response has content
      try {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          throw ApiException(
            message: data['message'] ?? 'Une erreur est survenue',
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
            message: 'Une erreur est survenue',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          message: 'Erreur de communication avec le serveur',
          statusCode: response.statusCode,
        );
      }
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}