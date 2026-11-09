import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/letting_event_model.dart';

enum EventsStatus { initial, loading, loaded, error }

class EventsProvider extends ChangeNotifier {
  EventsStatus _status = EventsStatus.initial;
  List<LettingEventModel> _events = [];
  String? _errorMessage;

  EventsStatus get status => _status;
  List<LettingEventModel> get events => _events;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUpcomingEvents() async {
    _status = EventsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        ApiConstants.upcomingLettings,
        requiresAuth: false,
      );

      if (response['success'] == true && response['events'] is List) {
        final list = response['events'] as List;
        _events = list.map((e) => LettingEventModel.fromJson(e)).toList();
        _status = EventsStatus.loaded;
      } else {
        _events = [];
        _status = EventsStatus.loaded;
      }
    } on ApiException catch (e) {
      debugPrint('[EventsProvider] ApiException: ${e.message}');
      _errorMessage = e.message;
      _status = EventsStatus.error;
    } catch (e) {
      debugPrint('[EventsProvider] Error: $e');
      _errorMessage = 'Could not load upcoming milk letting events.';
      _status = EventsStatus.error;
    }
    notifyListeners();
  }
}

