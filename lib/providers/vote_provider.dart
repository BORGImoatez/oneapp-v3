import 'package:flutter/material.dart';
import '../models/vote_model.dart';
import '../services/api_service.dart';
import '../services/building_context_service.dart';

class VoteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  final Map<int, List<Vote>> _channelVotes = {};
  final Map<int, Vote> _votes = {};
  bool _isLoading = false;
  String? _error;
  String? _currentBuildingContext;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Vote> getChannelVotes(int channelId) {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId) {
      print('DEBUG: Building context changed, clearing votes data');
      _channelVotes.clear();
      _votes.clear();
      _currentBuildingContext = currentBuildingId;
      notifyListeners();
      return [];
    }

    return _channelVotes[channelId] ?? [];
  }

  Vote? getVoteById(int voteId) {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId) {
      return null;
    }

    return _votes[voteId];
  }

  Future<void> loadChannelVotes(int channelId) async {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId) {
      print('DEBUG: Building context changed, clearing votes before loading');
      _channelVotes.clear();
      _votes.clear();
      _currentBuildingContext = currentBuildingId;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getChannelVotes(channelId);
      final votes = response
          .map((json) => Vote.fromJson(json))
          .toList();

      _channelVotes[channelId] = votes;

      // Mettre à jour le cache des votes individuels
      for (final vote in votes) {
        _votes[vote.id] = vote;
      }

    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVoteDetails(int voteId) async {
    try {
      final response = await _apiService.getVote(voteId);
      final vote = Vote.fromJson(response);

      _votes[voteId] = vote;

      // Mettre à jour dans la liste des canaux aussi
      for (final channelId in _channelVotes.keys) {
        final channelVotes = _channelVotes[channelId]!;
        final index = channelVotes.indexWhere((v) => v.id == voteId);
        if (index != -1) {
          channelVotes[index] = vote;
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> createVote(Map<String, dynamic> voteData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createVote(voteData);
      final vote = Vote.fromJson(response);

      final channelId = vote.channelId;
      final channelVotes = _channelVotes[channelId] ?? [];
      channelVotes.insert(0, vote);
      _channelVotes[channelId] = channelVotes;

      _votes[vote.id] = vote;

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitVote(Map<String, dynamic> voteData) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.submitVote(voteData);

      // Recharger les détails du vote pour avoir les résultats mis à jour
      final voteId = voteData['voteId'] as int;
      await loadVoteDetails(voteId);

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> closeVote(int voteId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.closeVote(voteId);
      final updatedVote = Vote.fromJson(response);

      _votes[voteId] = updatedVote;

      // Mettre à jour dans la liste des canaux
      for (final channelId in _channelVotes.keys) {
        final channelVotes = _channelVotes[channelId]!;
        final index = channelVotes.indexWhere((v) => v.id == voteId);
        if (index != -1) {
          channelVotes[index] = updatedVote;
          break;
        }
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAllData() {
    _channelVotes.clear();
    _votes.clear();
    _isLoading = false;
    _error = null;
    _currentBuildingContext = null;
    notifyListeners();
  }
}