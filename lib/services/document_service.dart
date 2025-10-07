import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/building_members_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class DocumentService {
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

  Future<List<FolderModel>> getRootFolders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/documents/folders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FolderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load folders');
      }
    } catch (e) {
      throw Exception('Error loading folders: $e');
    }
  }

  Future<List<FolderModel>> getSubFolders(int folderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/documents/folders/$folderId/subfolders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FolderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subfolders');
      }
    } catch (e) {
      throw Exception('Error loading subfolders: $e');
    }
  }

  Future<List<DocumentModel>> getFolderDocuments(int folderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/documents/folders/$folderId/documents'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Error loading documents: $e');
    }
  }

  Future<FolderModel> createFolder(String name, int? parentFolderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/documents/folders'),
        headers: headers,
        body: json.encode({
          'name': name,
          'parentFolderId': parentFolderId,
        }),
      );

      if (response.statusCode == 200) {
        return FolderModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create folder');
      }
    } catch (e) {
      throw Exception('Error creating folder: $e');
    }
  }

  Future<DocumentModel> uploadDocument(
    int folderId,
    File file, {
    String? description,
  }) async {
    try {
      final token = await _getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/documents/folders/$folderId/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return DocumentModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload document');
      }
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }

  Future<void> deleteFolder(int folderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/documents/folders/$folderId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete folder');
      }
    } catch (e) {
      throw Exception('Error deleting folder: $e');
    }
  }

  Future<void> deleteDocument(int documentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/documents/$documentId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/documents/search?query=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search documents');
      }
    } catch (e) {
      throw Exception('Error searching documents: $e');
    }
  }

  Future<BuildingMembersModel> getBuildingMembers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/documents/building-members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BuildingMembersModel.fromJson(data);
      } else {
        throw Exception('Failed to load building members');
      }
    } catch (e) {
      throw Exception('Error loading building members: $e');
    }
  }

  Future<FolderModel> updateFolderPermissions({
    required int folderId,
    required String shareType,
    List<String>? sharedResidentIds,
    List<String>? sharedApartmentIds,
    bool? allowUpload,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'shareType': shareType,
        if (sharedResidentIds != null && sharedResidentIds.isNotEmpty)
          'sharedResidentIds': sharedResidentIds,
        if (sharedApartmentIds != null && sharedApartmentIds.isNotEmpty)
          'sharedApartmentIds': sharedApartmentIds,
        if (allowUpload != null) 'allowUpload': allowUpload,
      };

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/documents/folders/$folderId/permissions'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FolderModel.fromJson(data);
      } else {
        throw Exception('Failed to update permissions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating permissions: $e');
    }
  }

  Future<File?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }

  String getFileIcon(String? mimeType, String? extension) {
    if (mimeType == null && extension == null) {
      return 'file';
    }

    if (mimeType?.startsWith('image/') ?? false) {
      return 'image';
    }
    if (mimeType == 'application/pdf') {
      return 'pdf';
    }
    if (mimeType?.contains('word') ?? false) {
      return 'doc';
    }
    if (mimeType?.contains('excel') ?? false ||
        mimeType!.contains('spreadsheet') ?? false) {
      return 'excel';
    }
    if (mimeType?.contains('powerpoint') ?? false ||
        mimeType!.contains('presentation') ?? false) {
      return 'ppt';
    }
    if (mimeType?.startsWith('video/') ?? false) {
      return 'video';
    }
    if (mimeType?.startsWith('audio/') ?? false) {
      return 'audio';
    }
    if (mimeType?.contains('zip') ?? false ||
        mimeType!.contains('rar') ?? false ||
        mimeType!.contains('compressed') ?? false) {
      return 'archive';
    }

    return 'file';
  }
}
