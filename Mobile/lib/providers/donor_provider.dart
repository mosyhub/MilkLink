import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/donor_model.dart';

enum DonorStatus { initial, loading, loaded, empty, error }

class DonorProvider extends ChangeNotifier {
  DonorStatus _status = DonorStatus.initial;
  DonorModel? _donor;
  String? _errorMessage;
  bool _hasDonorProfile = false;

  DonorStatus get status => _status;
  DonorModel? get donor => _donor;
  String? get errorMessage => _errorMessage;
  bool get hasDonorProfile => _hasDonorProfile;

  Future<void> fetchMyDonorProfile() async {
    _status = DonorStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiConstants.donorMe);
      if (response['success'] == true) {
        _hasDonorProfile = response['hasDonorProfile'] == true;
        if (_hasDonorProfile && response['donor'] != null) {
          _donor = DonorModel.fromJson(response['donor']);
          _status = DonorStatus.loaded;
        } else {
          _donor = null;
          _status = DonorStatus.empty;
        }
      } else {
        _status = DonorStatus.empty;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = DonorStatus.error;
    } catch (e) {
      _errorMessage = 'Could not load donor profile.';
      _status = DonorStatus.error;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> registerFirstTimeDonor({
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime birthday,
    required String street,
    required String brgy,
    String city = 'Pasig City',
    required String contactNumber,
    String? occupation,
    String donorType = 'Community',
    String? childName,
    DateTime? childBirthday,
    String? birthWeight,
    String? breastfeedingInfo,
    Map<String, dynamic>? questionnaireAnswers,
  }) async {
    _status = DonorStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'birthday': birthday.toIso8601String(),
        'street': street,
        'brgy': brgy,
        'city': city,
        'contactNumber': contactNumber,
        'occupation': occupation,
        'donorType': donorType,
        'childName': childName,
        'childBirthday': childBirthday?.toIso8601String(),
        'birthWeight': birthWeight,
        'breastfeedingInfo': breastfeedingInfo,
        'questionnaireAnswers': questionnaireAnswers,
      };

      final response = await ApiClient.post(
        ApiConstants.donorRegister,
        data: payload,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        if (response['donor'] != null) {
          _donor = DonorModel.fromJson(response['donor']);
          _hasDonorProfile = true;
          _status = DonorStatus.loaded;
        }
        notifyListeners();
        return {
          'success': true,
          'donorId': response['donorId'],
          'qrCodeData': response['qrCodeData'],
          'claimToken': response['claimToken'],
          'nextSteps': response['nextSteps'] ?? [],
        };
      }

      _errorMessage = response['message'] ?? 'Registration failed';
      _status = DonorStatus.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = DonorStatus.error;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (e) {
      _errorMessage = 'Registration error: ${e.toString()}';
      _status = DonorStatus.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<List<DonorModel>> searchReturningDonor(String query) async {
    try {
      final response = await ApiClient.get(
        '${ApiConstants.donorSearchReturning}?query=${Uri.encodeComponent(query)}',
        requiresAuth: false,
      );
      if (response['success'] == true && response['donors'] is List) {
        return (response['donors'] as List)
            .map((d) => DonorModel.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> submitScreeningApplication({
    required String street,
    required String brgy,
    required String city,
    required DateTime birthday,
    required String donorType,
    required String childName,
    required DateTime childBirthday,
    required String birthWeight,
    required Map<String, dynamic> questionnaireAnswers,
  }) async {
    _status = DonorStatus.loading;
    notifyListeners();

    try {
      // Build the standard MilkLink fields payload
      final List<Map<String, dynamic>> fields = [
        {'label': 'street', 'value': street, 'type': 'INPUT_TEXT'},
        {'label': 'brgy', 'value': brgy, 'type': 'INPUT_TEXT'},
        {'label': 'city', 'value': city, 'type': 'INPUT_TEXT'},
        {'label': 'birthday', 'value': birthday.toIso8601String(), 'type': 'INPUT_DATE'},
        {'label': 'donorType', 'value': donorType, 'type': 'INPUT_TEXT'},
        {'label': 'child_name', 'value': childName, 'type': 'INPUT_TEXT'},
        {'label': 'child_birthday', 'value': childBirthday.toIso8601String(), 'type': 'INPUT_DATE'},
        {'label': 'birth_weight', 'value': birthWeight, 'type': 'INPUT_TEXT'},
      ];

      questionnaireAnswers.forEach((key, val) {
        fields.add({
          'label': key,
          'value': [val],
          'type': 'MULTIPLE_CHOICE',
          'options': [
            {'id': 'opt_yes', 'text': 'Yes'},
            {'id': 'opt_no', 'text': 'No'},
            {'id': 'opt_na', 'text': 'None of the above'},
          ]
        });
      });

      final payload = {
        'data': {
          'submissionId': 'mob_${DateTime.now().millisecondsSinceEpoch}',
          'fields': fields,
        }
      };

      final response = await ApiClient.post(
        ApiConstants.submitDonorApplication,
        data: payload,
      );

      if (response['success'] == true) {
        await fetchMyDonorProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Application submission failed: ${e.toString()}';
      _status = DonorStatus.error;
      notifyListeners();
      return false;
    }
  }
}

