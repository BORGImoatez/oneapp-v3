import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/call_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class CallService {
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

  Future<CallModel> initiateCall({
    required int channelId,
    required String receiverId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/calls/initiate'),
        headers: headers,
        body: jsonEncode({
          'channelId': channelId,
          'receiverId': receiverId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CallModel.fromJson(data);
      } else {
        throw Exception('Failed to initiate call');
      }
    } catch (e) {
      throw Exception('Error initiating call: $e');
    }
  }

  Future<CallModel> answerCall(int callId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/calls/$callId/answer'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CallModel.fromJson(data);
      } else {
        throw Exception('Failed to answer call');
      }
    } catch (e) {
      throw Exception('Error answering call: $e');
    }
  }

  Future<CallModel> endCall(int callId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/calls/$callId/end'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CallModel.fromJson(data);
      } else {
        throw Exception('Failed to end call');
      }
    } catch (e) {
      throw Exception('Error ending call: $e');
    }
  }

  Future<CallModel> rejectCall(int callId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/calls/$callId/reject'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CallModel.fromJson(data);
      } else {
        throw Exception('Failed to reject call');
      }
    } catch (e) {
      throw Exception('Error rejecting call: $e');
    }
  }

  Future<List<CallModel>> getCallHistory(int channelId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/calls/channel/$channelId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CallModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load call history');
      }
    } catch (e) {
      throw Exception('Error fetching call history: $e');
    }
  }
}
