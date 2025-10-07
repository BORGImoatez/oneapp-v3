import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<FolderModel> _folders = [];
  List<DocumentModel> _documents = [];
  List<FolderModel> _navigationStack = [];
  bool _isLoading = false;
  String? _error;

  List<FolderModel> get folders => _folders;
  List<DocumentModel> get documents => _documents;
  List<FolderModel> get navigationStack => _navigationStack;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canGoBack => _navigationStack.isNotEmpty;

  FolderModel? get currentFolder =>
      _navigationStack.isEmpty ? null : _navigationStack.last;

  Future<void> loadRootFolders() async {
    _isLoading = true;
    _error = null;
    _navigationStack.clear();
    notifyListeners();

    try {
      _folders = await _documentService.getRootFolders();
      _documents = [];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _folders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openFolder(FolderModel folder) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final subFolders = await _documentService.getSubFolders(folder.id);
      final documents = await _documentService.getFolderDocuments(folder.id);

      _navigationStack.add(folder);
      _folders = subFolders;
      _documents = documents;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goBack() async {
    if (_navigationStack.isEmpty) return;

    _navigationStack.removeLast();

    if (_navigationStack.isEmpty) {
      await loadRootFolders();
    } else {
      final parentFolder = _navigationStack.last;
      _navigationStack.removeLast();
      await openFolder(parentFolder);
    }
  }

  Future<void> createFolder(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final parentFolderId = currentFolder?.id;
      await _documentService.createFolder(name, parentFolderId);

      if (parentFolderId == null) {
        await loadRootFolders();
      } else {
        final subFolders = await _documentService.getSubFolders(parentFolderId);
        _folders = subFolders;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadDocument(File file, {String? description}) async {
    if (currentFolder == null) {
      _error = 'Please select a folder first';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _documentService.uploadDocument(
        currentFolder!.id,
        file,
        description: description,
      );

      final documents =
          await _documentService.getFolderDocuments(currentFolder!.id);
      _documents = documents;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFolder(int folderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _documentService.deleteFolder(folderId);

      if (currentFolder == null) {
        await loadRootFolders();
      } else {
        final subFolders = await _documentService.getSubFolders(currentFolder!.id);
        _folders = subFolders;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDocument(int documentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _documentService.deleteDocument(documentId);

      if (currentFolder != null) {
        final documents =
            await _documentService.getFolderDocuments(currentFolder!.id);
        _documents = documents;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_navigationStack.isEmpty) {
      await loadRootFolders();
    } else {
      final current = _navigationStack.last;
      _navigationStack.removeLast();
      await openFolder(current);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
