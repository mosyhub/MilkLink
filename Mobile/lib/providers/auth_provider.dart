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

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

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

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password},
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

  Future<bool> register({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiConstants.register,
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'middleName': middleName?.trim(),
          'email': email.trim(),
          'phoneNumber': phone.trim(),
          'pass': password,
          'role': 'User',
        },
        requiresAuth: false,
      );

      if (response['success'] == true) {
        // Automatically attempt login after successful registration
        return await login(email, password);
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

  Future<void> logout() async {
    await SessionManager.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

