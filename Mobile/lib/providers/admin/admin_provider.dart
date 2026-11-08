import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/admin/admin_models.dart';

enum AdminLoadStatus { initial, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  AdminLoadStatus _status = AdminLoadStatus.initial;
  AdminDashboardData _data = const AdminDashboardData();
  String? _errorMessage;

  AdminLoadStatus get status => _status;
  AdminDashboardData get data => _data;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _status = AdminLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final responses = await Future.wait<dynamic>([
        _getMap(ApiConstants.adminMetrics),
        _getList(ApiConstants.inventories, const ['inventories', 'inventory']),
        _getList(ApiConstants.pickups, const ['pickups', 'data']),
        _getList(ApiConstants.schedules, const ['schedules', 'data']),
        _getList(ApiConstants.adminUsers, const ['users', 'staff']),
        _getList(ApiConstants.articles, const ['articles', 'data']),
        _getList(ApiConstants.announcements, const ['announcements', 'data']),
      ]);

      _data = AdminDashboardData(
        metrics: responses[0] as Map<String, dynamic>,
        inventory: responses[1] as List<Map<String, dynamic>>,
        pickups: responses[2] as List<Map<String, dynamic>>,
        schedules: responses[3] as List<Map<String, dynamic>>,
        accounts: responses[4] as List<Map<String, dynamic>>,
        articles: responses[5] as List<Map<String, dynamic>>,
        announcements: responses[6] as List<Map<String, dynamic>>,
      );
      _status = AdminLoadStatus.loaded;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = AdminLoadStatus.error;
    } catch (error) {
      _errorMessage = 'Unable to load admin data: $error';
      _status = AdminLoadStatus.error;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> _getMap(String endpoint) async {
    final response = await ApiClient.get(endpoint);
    if (response is! Map) {
      throw ApiException('Invalid response from $endpoint');
    }
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> _getList(
    String endpoint,
    List<String> keys,
  ) async {
    final response = await ApiClient.get(endpoint);
    if (response is! Map) return const [];
    for (final key in keys) {
      final value = response[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return const [];
  }
}
