import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/session_manager.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ApiConstants.clientTypeHeader: ApiConstants.clientTypeValue,
    };

    if (requiresAuth) {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw ApiException(body['message'] ?? 'Unauthorized. Please login again.', 401);
    } else if (response.statusCode == 403) {
      throw ApiException(body['message'] ?? 'Forbidden. You do not have access.', 403);
    } else if (response.statusCode == 404) {
      throw ApiException(body['message'] ?? 'Requested resource not found.', 404);
    } else {
      final message = body is Map
          ? (body['message'] ?? body['error'] ?? 'Something went wrong (${response.statusCode})')
          : 'Something went wrong (${response.statusCode})';
      throw ApiException(message.toString(), response.statusCode);
    }
  }

  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot reach the server. Make sure the backend is running and your device is connected to the same network.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<dynamic> post(
    String url, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot reach the server. Make sure the backend is running and your device is connected to the same network.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<dynamic> put(
    String url, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot reach the server. Make sure the backend is running and your device is connected to the same network.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Cannot reach the server. Make sure the backend is running and your device is connected to the same network.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }
}
