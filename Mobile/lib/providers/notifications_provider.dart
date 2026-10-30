import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';

enum NotifStatus { initial, loading, loaded, error }

class NotificationsProvider extends ChangeNotifier {
  NotifStatus _status = NotifStatus.initial;
  List<NotificationItem> _notifications = [];
  int _unseenCount = 0;
  String? _errorMessage;

  NotifStatus get status => _status;
  List<NotificationItem> get notifications => _notifications;
  int get unseenCount => _unseenCount;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    _status = NotifStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiConstants.notifications);
      if (response['success'] == true && response['notifications'] is List) {
        final list = response['notifications'] as List;
        _notifications = list.map((n) => NotificationItem.fromJson(n)).toList();
        _unseenCount = response['unseen'] ?? _notifications.where((n) => !n.seen).length;
        _status = NotifStatus.loaded;
      } else {
        _notifications = [];
        _unseenCount = 0;
        _status = NotifStatus.loaded;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = NotifStatus.error;
    } catch (e) {
      _errorMessage = 'Could not load notifications.';
      _status = NotifStatus.error;
    }
    notifyListeners();
  }

  Future<void> markAsSeen(String id) async {
    try {
      await ApiClient.put(ApiConstants.markNotificationSeen(id));
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final current = _notifications[index];
        _notifications[index] = NotificationItem(
          id: current.id,
          title: current.title,
          body: current.body,
          seen: true,
          notifiedAt: current.notifiedAt,
        );
        if (_unseenCount > 0) _unseenCount--;
        notifyListeners();
      }
    } catch (_) {}
  }
}

