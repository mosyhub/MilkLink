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
      // Build the standard TCHMB fields payload
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

