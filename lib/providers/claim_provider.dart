import 'dart:io';
import 'package:flutter/material.dart';
import '../models/claim_model.dart';
import '../services/claim_service.dart';

class ClaimProvider with ChangeNotifier {
  final ClaimService _claimService = ClaimService();

  List<ClaimModel> _claims = [];
  ClaimModel? _selectedClaim;
  bool _isLoading = false;
  String? _errorMessage;

  List<ClaimModel> get claims => _claims;
  ClaimModel? get selectedClaim => _selectedClaim;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadClaims(int buildingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _claims = await _claimService.getClaimsByBuilding(buildingId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadClaimById(int claimId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedClaim = await _claimService.getClaimById(claimId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createClaim({
    required int apartmentId,
    required List<String> claimTypes,
    required String cause,
    required String description,
    String? insuranceCompany,
    String? insurancePolicyNumber,
    List<int>? affectedApartmentIds,
    List<File>? photos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newClaim = await _claimService.createClaim(
        apartmentId: apartmentId,
        claimTypes: claimTypes,
        cause: cause,
        description: description,
        insuranceCompany: insuranceCompany,
        insurancePolicyNumber: insurancePolicyNumber,
        affectedApartmentIds: affectedApartmentIds,
        photos: photos,
      );

      _claims.insert(0, newClaim);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClaimStatus(int claimId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedClaim = await _claimService.updateClaimStatus(claimId, status);

      final index = _claims.indexWhere((c) => c.id == claimId);
      if (index != -1) {
        _claims[index] = updatedClaim;
      }

      if (_selectedClaim?.id == claimId) {
        _selectedClaim = updatedClaim;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClaim(int claimId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _claimService.deleteClaim(claimId);
      _claims.removeWhere((c) => c.id == claimId);

      if (_selectedClaim?.id == claimId) {
        _selectedClaim = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedClaim() {
    _selectedClaim = null;
    notifyListeners();
  }
}
