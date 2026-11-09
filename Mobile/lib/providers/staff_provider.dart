import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/donor_model.dart';
import '../models/patient_model.dart';
import '../models/request_model.dart';

enum StaffLoadingStatus { initial, loading, success, error }

class StaffProvider extends ChangeNotifier {
  StaffLoadingStatus _status = StaffLoadingStatus.initial;
  String? _errorMessage;
  String? _lastCreatedClaimToken;
  String? _lastCreatedQrCodeData;

  // Donors
  List<DonorModel> _activeDonors = [];
  List<DonorModel> _archivedDonors = [];

  // Patients (Recipients)
  List<PatientModel> _activePatients = [];
  List<PatientModel> _archivedPatients = [];

  // Requests
  List<RequestModel> _activeRequests = [];
  List<RequestModel> _archivedRequests = [];

  // Auxiliary counts for dashboard badges
  int _activeSchedulesCount = 0;
  int _activeInventoryCount = 0;
  int _pendingRegistrationsCount = 0;
  int _screeningAppointmentsCount = 0;

  StaffLoadingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get lastCreatedClaimToken => _lastCreatedClaimToken;
  String? get lastCreatedQrCodeData => _lastCreatedQrCodeData;

  List<DonorModel> get activeDonors => _activeDonors;
  List<DonorModel> get archivedDonors => _archivedDonors;

  List<PatientModel> get activePatients => _activePatients;
  List<PatientModel> get archivedPatients => _archivedPatients;

  List<RequestModel> get activeRequests => _activeRequests;
  List<RequestModel> get archivedRequests => _archivedRequests;

  int get activeSchedulesCount => _activeSchedulesCount;
  int get activeInventoryCount => _activeInventoryCount;
  int get pendingRegistrationsCount => _pendingRegistrationsCount;
  int get screeningAppointmentsCount => _screeningAppointmentsCount;

  Future<void> fetchDashboardCounts() async {
    try {
      final responses = await Future.wait([
        ApiClient.get(ApiConstants.schedules),
        ApiClient.get(ApiConstants.inventories),
        ApiClient.get(ApiConstants.staffPendingRegistrations),
        ApiClient.get(ApiConstants.staffScreeningAppointments),
      ]);
      if (responses[0] is Map && responses[0]['schedules'] is List) {
        _activeSchedulesCount = (responses[0]['schedules'] as List).length;
      }
      if (responses[1] is Map && responses[1]['inventories'] is List) {
        _activeInventoryCount = (responses[1]['inventories'] as List).length;
      }
      if (responses[2] is Map && responses[2]['registrations'] is List) {
        _pendingRegistrationsCount = (responses[2]['registrations'] as List).length;
      }
      if (responses[3] is Map && responses[3]['appointments'] is List) {
        _screeningAppointmentsCount = (responses[3]['appointments'] as List).length;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DONOR CRUD & ARCHIVE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchDonors({bool isArchived = false}) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = isArchived ? ApiConstants.archivedDonors : ApiConstants.donors;
      final response = await ApiClient.get(url);

      if (response['success'] == true && response['donors'] is List) {
        final list = (response['donors'] as List)
            .map((d) => DonorModel.fromJson(d))
            .toList();

        if (isArchived) {
          _archivedDonors = list;
        } else {
          _activeDonors = list;
        }
        _status = StaffLoadingStatus.success;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load donors';
        _status = StaffLoadingStatus.error;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
    } catch (e) {
      _errorMessage = 'Error loading donors: $e';
      _status = StaffLoadingStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createDonor(Map<String, dynamic> data) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(ApiConstants.staffCreateDonor, data: data);
      if (response['success'] == true) {
        _lastCreatedClaimToken = response['claimToken'] as String?;
        _lastCreatedQrCodeData = response['qrCodeData'] as String?;
        await fetchDonors(isArchived: false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create donor';
        _status = StaffLoadingStatus.error;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error creating donor: $e';
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDonor(String id, Map<String, dynamic> data) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.put(ApiConstants.donorById(id), data: data);
      if (response['success'] == true) {
        await fetchDonors(isArchived: false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update donor';
        _status = StaffLoadingStatus.error;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error updating donor: $e';
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDeleteDonor(String id) async {
    try {
      final response = await ApiClient.put(ApiConstants.softDeleteDonor(id));
      if (response['success'] == true) {
        await fetchDonors(isArchived: false);
        await fetchDonors(isArchived: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to archive donor';
    }
    notifyListeners();
    return false;
  }

  Future<bool> restoreDonor(String id) async {
    try {
      final response = await ApiClient.put(ApiConstants.restoreDonor(id));
      if (response['success'] == true) {
        await fetchDonors(isArchived: false);
        await fetchDonors(isArchived: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to restore donor';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteDonorPermanently(String id) async {
    try {
      final response = await ApiClient.delete(ApiConstants.donorById(id));
      if (response['success'] == true) {
        await fetchDonors(isArchived: true);
        await fetchDonors(isArchived: false);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete donor';
    }
    notifyListeners();
    return false;
  }

  Future<String?> generateDonorClaimToken(String id) async {
    try {
      final response = await ApiClient.post(ApiConstants.donorClaimToken(id));
      if (response['success'] == true && response['claimToken'] != null) {
        _lastCreatedClaimToken = response['claimToken'] as String?;
        _lastCreatedQrCodeData = response['qrCodeData'] as String?;
        return response['claimToken'] as String;
      }
      _errorMessage = response['message'] ?? 'Failed to generate claim token';
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to generate claim token: $e';
    }
    notifyListeners();
    return null;
  }

  Future<bool> updateDonorScreeningStatus(String id, String status, {String? reviewNotes}) async {
    try {
      final response = await ApiClient.put(
        ApiConstants.donorScreeningStatus(id),
        data: {
          'eligibility': status,
          if (reviewNotes != null && reviewNotes.isNotEmpty) 'reviewNotes': reviewNotes,
        },
      );
      if (response['success'] == true) {
        await fetchDonors(isArchived: false);
        return true;
      }
      _errorMessage = response['message'] ?? 'Failed to update status';
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update screening status: $e';
    }
    notifyListeners();
    return false;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PATIENT / RECIPIENT CRUD & ARCHIVE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchPatients({bool isArchived = false}) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = isArchived ? ApiConstants.archivedPatients : ApiConstants.patients;
      final response = await ApiClient.get(url);

      if (response['success'] == true && response['patients'] is List) {
        final list = (response['patients'] as List)
            .map((p) => PatientModel.fromJson(p))
            .toList();

        if (isArchived) {
          _archivedPatients = list;
        } else {
          _activePatients = list;
        }
        _status = StaffLoadingStatus.success;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load recipients';
        _status = StaffLoadingStatus.error;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
    } catch (e) {
      _errorMessage = 'Error loading recipients: $e';
      _status = StaffLoadingStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createPatient(Map<String, dynamic> data) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(ApiConstants.staffCreatePatient, data: data);
      if (response['success'] == true) {
        _lastCreatedClaimToken = response['claimToken'] as String?;
        _lastCreatedQrCodeData = response['qrCodeData'] as String?;
        await fetchPatients(isArchived: false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create recipient';
        _status = StaffLoadingStatus.error;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error creating recipient: $e';
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePatient(String id, Map<String, dynamic> data) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.put(ApiConstants.patientById(id), data: data);
      if (response['success'] == true) {
        await fetchPatients(isArchived: false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update recipient';
        _status = StaffLoadingStatus.error;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error updating recipient: $e';
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDeletePatient(String id) async {
    try {
      final response = await ApiClient.put(ApiConstants.softDeletePatient(id));
      if (response['success'] == true) {
        await fetchPatients(isArchived: false);
        await fetchPatients(isArchived: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to archive recipient';
    }
    notifyListeners();
    return false;
  }

  Future<bool> restorePatient(String id) async {
    try {
      final response = await ApiClient.put(ApiConstants.restorePatient(id));
      if (response['success'] == true) {
        await fetchPatients(isArchived: false);
        await fetchPatients(isArchived: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to restore recipient';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deletePatientPermanently(String id) async {
    try {
      final response = await ApiClient.delete(ApiConstants.patientById(id));
      if (response['success'] == true) {
        await fetchPatients(isArchived: true);
        await fetchPatients(isArchived: false);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete recipient';
    }
    notifyListeners();
    return false;
  }

  Future<String?> generatePatientClaimToken(String id) async {
    try {
      final response = await ApiClient.post(ApiConstants.patientClaimToken(id));
      if (response['success'] == true && response['claimToken'] != null) {
        _lastCreatedClaimToken = response['claimToken'] as String?;
        _lastCreatedQrCodeData = response['qrCodeData'] as String?;
        return response['claimToken'] as String;
      }
      _errorMessage = response['message'] ?? 'Failed to generate claim token';
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to generate claim token: $e';
    }
    notifyListeners();
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REQUEST CRUD & ARCHIVE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchRequests({bool isArchived = false}) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = isArchived ? ApiConstants.archivedRequests : ApiConstants.requests;
      final response = await ApiClient.get(url);

      if (response['success'] == true && response['requests'] is List) {
        final list = (response['requests'] as List)
            .map((r) => RequestModel.fromJson(r))
            .toList();

        if (isArchived) {
          _archivedRequests = list;
        } else {
          _activeRequests = list;
        }
        _status = StaffLoadingStatus.success;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load requests';
        _status = StaffLoadingStatus.error;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
    } catch (e) {
      _errorMessage = 'Error loading requests: $e';
      _status = StaffLoadingStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createRequest(Map<String, dynamic> data) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(ApiConstants.requests, data: data);
      if (response['success'] == true) {
        await fetchRequests(isArchived: false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create request';
        _status = StaffLoadingStatus.error;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error creating request: $e';
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRequest(String id, Map<String, dynamic> data) async {
    _status = StaffLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.put(ApiConstants.requestById(id), data: data);
      if (response['success'] == true) {
        await fetchRequests(isArchived: false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update request';
        _status = StaffLoadingStatus.error;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error updating request: $e';
      _status = StaffLoadingStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDeleteRequest(String id) async {
    try {
      final response = await ApiClient.put(ApiConstants.softDeleteRequest(id));
      if (response['success'] == true) {
        await fetchRequests(isArchived: false);
        await fetchRequests(isArchived: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to archive request';
    }
    notifyListeners();
    return false;
  }

  Future<bool> restoreRequest(String id) async {
    try {
      final response = await ApiClient.put(ApiConstants.restoreRequest(id));
      if (response['success'] == true) {
        await fetchRequests(isArchived: false);
        await fetchRequests(isArchived: true);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to restore request';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteRequestPermanently(String id) async {
    try {
      final response = await ApiClient.delete(ApiConstants.requestById(id));
      if (response['success'] == true) {
        await fetchRequests(isArchived: true);
        await fetchRequests(isArchived: false);
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete request';
    }
    notifyListeners();
    return false;
  }
}

