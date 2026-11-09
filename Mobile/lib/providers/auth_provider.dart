import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/utils/session_manager.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  // Granular Status Dimensions
  String _accountStatus = 'Active';
  String _donorRegistrationStatus = 'Unregistered';
  String _donorEligibilityStatus = 'Not Screened';
  bool _isDonorEligible = false;
  String _milkRequestStatus = 'None';
  bool _hasActiveMilkRequest = false;
  Map<String, dynamic>? _donorProfile;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStaff => _user?.isStaff ?? false;

  String get accountStatus => _accountStatus;
  String get donorRegistrationStatus => _donorRegistrationStatus;
  String get donorEligibilityStatus => _donorEligibilityStatus;
  bool get isDonorEligible => _isDonorEligible;
  String get milkRequestStatus => _milkRequestStatus;
  bool get hasActiveMilkRequest => _hasActiveMilkRequest;
  Map<String, dynamic>? get donorProfile => _donorProfile;

  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isLoggedIn = await SessionManager.isLoggedIn();
      if (!isLoggedIn) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      await loadCurrentUser();
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      final response = await ApiClient.get(ApiConstants.userProfile);
      if (response['success'] == true && response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
        _accountStatus = response['accountStatus'] ?? 'Active';
        _donorRegistrationStatus = response['donorRegistrationStatus'] ?? 'Unregistered';
        _donorEligibilityStatus = response['donorEligibilityStatus'] ?? 'Not Screened';
        _isDonorEligible = response['isDonorEligible'] == true;
        _milkRequestStatus = response['milkRequestStatus'] ?? 'None';
        _hasActiveMilkRequest = response['hasActiveMilkRequest'] == true;
        _donorProfile = response['donorProfile'];
        _status = AuthStatus.authenticated;
      } else {
        await SessionManager.clearSession();
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      await SessionManager.clearSession();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Securely links an existing staff-created donor record to the verified account
  Future<Map<String, dynamic>> linkExistingDonorRecord(String tokenOrQr) async {
    try {
      final response = await ApiClient.post(
        ApiConstants.linkDonorRecord,
        data: {'claimToken': tokenOrQr.trim()},
      );

      if (response['success'] == true) {
        await loadCurrentUser();
        return {'success': true, 'message': response['message'] ?? 'Donor record linked successfully.'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to link donor record'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Login using a username OR email as the identifier.
  Future<bool> login(String identifier, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiConstants.login,
        data: {'identifier': identifier.trim(), 'password': password},
        requiresAuth: false,
      );

      if (response['success'] == true && response['token'] != null) {
        final token = response['token'] as String;
        final userJson = response['user'];
        _user = UserModel.fromJson(userJson);

        await SessionManager.saveSession(
          token: token,
          refreshToken: response['refreshToken'],
          userId: _user!.id,
          role: _user!.role,
        );

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        throw ApiException(response['message'] ?? 'Login failed');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user. [email] is optional.
  Future<bool> register({
    required String firstName,
    required String lastName,
    String? middleName,
    required String username,
    String? email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim().toLowerCase(),
        'phoneNumber': phone.trim(),
        'password': password,
        'role': 'User',
      };

      if (middleName != null && middleName.trim().isNotEmpty) {
        payload['middleName'] = middleName.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim().toLowerCase();
      }

      final response = await ApiClient.post(
        ApiConstants.register,
        data: payload,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        // Registration returns a token directly; parse user from response.
        if (response['token'] != null) {
          final token = response['token'] as String;
          final userJson = response['user'];
          _user = UserModel.fromJson(userJson);

          await SessionManager.saveSession(
            token: token,
            refreshToken: response['refreshToken'],
            userId: _user!.id,
            role: _user!.role,
          );

          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
        // Fallback: auto-login using username after successful registration
        return await login(username.trim().toLowerCase(), password);
      } else {
        throw ApiException(response['message'] ?? 'Registration failed');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during registration.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await ApiClient.post(
        ApiConstants.forgotPassword,
        data: {'email': email.trim()},
        requiresAuth: false,
      );
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Flow A: Direct Self-Registration (Donor or Patient)
  Future<bool> selfRegister({
    required String firstName,
    required String lastName,
    String? middleName,
    required String username,
    required String phone,
    required String password,
    required String profileType, // 'Donor' or 'Patient'
    required Map<String, dynamic> homeAddress,
    DateTime? birthday,
    String? donorType,
    String? occupation,
    String? patientName,
    String? motherName,
    String? patientType,
    String? age,
    String? aog,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'profileType': profileType,
        'home_address': homeAddress,
      };

      if (middleName != null && middleName.trim().isNotEmpty) {
        payload['middleName'] = middleName.trim();
      }

      if (profileType == 'Donor') {
        if (birthday != null) payload['birthday'] = birthday.toIso8601String();
        if (donorType != null) payload['donorType'] = donorType;
        if (occupation != null) payload['occupation'] = occupation;
      } else if (profileType == 'Patient') {
        if (patientName != null) payload['patientName'] = patientName;
        if (motherName != null) payload['motherName'] = motherName;
        if (patientType != null) payload['patientType'] = patientType;
        if (age != null) payload['age'] = age;
        if (aog != null) payload['aog'] = aog;
      }

      final response = await ApiClient.post(
        ApiConstants.selfRegister,
        data: payload,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        if (response['token'] != null) {
          final token = response['token'] as String;
          final userJson = response['user'];
          _user = UserModel.fromJson(userJson);
          await SessionManager.saveSession(
            token: token,
            refreshToken: response['refreshToken'],
            userId: _user!.id,
            role: _user!.role,
          );
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        throw ApiException(response['message'] ?? 'Self-registration failed');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during registration: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Step 1 of Claiming: Verify Claim Token or Scanned QR Data with the Backend
  Future<Map<String, dynamic>?> verifyClaimToken(String tokenOrQrData) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiConstants.verifyClaim,
        data: {'claimToken': tokenOrQrData.trim()},
        requiresAuth: false,
      );

      if (response['success'] == true && response['valid'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return response as Map<String, dynamic>;
      } else {
        _errorMessage = response['message'] ?? 'Invalid claim token';
        _status = AuthStatus.error;
        notifyListeners();
        return null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Verification failed: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Step 2 of Claiming: Bind Existing Record using Token & Credentials
  Future<bool> claimRecord({
    required String claimToken,
    required String username,
    required String password,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? profileType,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> payload = {
        'claimToken': claimToken.trim().toUpperCase(),
        'username': username.trim().toLowerCase(),
        'password': password,
      };
      if (email != null && email.trim().isNotEmpty) payload['email'] = email.trim().toLowerCase();
      if (phone != null && phone.trim().isNotEmpty) payload['phone'] = phone.trim();
      if (firstName != null && firstName.trim().isNotEmpty) payload['firstName'] = firstName.trim();
      if (lastName != null && lastName.trim().isNotEmpty) payload['lastName'] = lastName.trim();
      if (profileType != null && profileType.isNotEmpty) payload['profileType'] = profileType;

      final response = await ApiClient.post(
        ApiConstants.claimRecord,
        data: payload,
        requiresAuth: false,
      );

      if (response['success'] == true) {
        if (response['token'] != null) {
          final token = response['token'] as String;
          final userJson = response['user'];
          _user = UserModel.fromJson(userJson);
          await SessionManager.saveSession(
            token: token,
            refreshToken: response['refreshToken'],
            userId: _user!.id,
            role: _user!.role,
          );
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        throw ApiException(response['message'] ?? 'Claiming record failed');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred while claiming record: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Update logged in user profile (name, username, email, phone, avatar, employeeID, password)
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.put(
        ApiConstants.updateProfile,
        data: data,
        requiresAuth: true,
      );

      if (response['success'] == true && response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        throw ApiException(response['message'] ?? 'Profile update failed');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred while updating profile: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Change password explicitly via /password/update
  Future<bool> updatePassword({
    required String oldPassword,
    required String password,
    required String confirmPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.put(
        ApiConstants.updatePassword,
        data: {
          'oldPassword': oldPassword,
          'password': password,
          'confirmPassword': confirmPassword,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        throw ApiException(response['message'] ?? 'Password update failed');
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred while updating password: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SessionManager.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
