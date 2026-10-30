import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api/v1';
    }
    if (Platform.isAndroid) {
      // Use PC Wi-Fi IP for physical devices (e.g., RMX3867).
      // If using Android Emulator, switch to 10.0.2.2 via the Settings gear icon on the login screen.
      return 'http://192.168.100.8:4000/api/v1';
    }
    return 'http://localhost:4000/api/v1';
  }

  // Active Base URL (can be customized at runtime)
  static String baseUrl = defaultBaseUrl;

  // Header Constants
  static const String clientTypeHeader = 'x-client-type';
  static const String clientTypeValue = 'mobile';

  // Auth Endpoints
  static String get register => '$baseUrl/register';
  static String get login => '$baseUrl/login';
  static String get userProfile => '$baseUrl/me';
  static String get updateProfile => '$baseUrl/me/update';
  static String get updatePassword => '$baseUrl/password/update';
  static String get forgotPassword => '$baseUrl/password/reset';

  // Donor Endpoints
  static String get donorMe => '$baseUrl/donor/me';
  static String get submitDonorApplication => '$baseUrl/donors';
  static String get checkEligibility => '$baseUrl/check-eligibility';

  // Events & Schedules Endpoints
  static String get upcomingLettings => '$baseUrl/upcoming/lettings';
  static String get publicNewDonorEvent => '$baseUrl/letting-newDonor';

  // Resources & Announcements
  static String get articles => '$baseUrl/articles';
  static String get announcements => '$baseUrl/announcements';

  // Notifications
  static String get notifications => '$baseUrl/notifications';
  static String get registerNotificationToken => '$baseUrl/notifications/check';
  static String markNotificationSeen(String id) => '$baseUrl/notifications/$id';
}

