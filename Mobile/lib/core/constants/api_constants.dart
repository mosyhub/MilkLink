class ApiConstants {
  // ── Connection ─────────────────────────────────────────────────────────────
  // 10.0.2.2 = Android's permanent alias for the development machine's
  // localhost. Works on all emulators and physical devices (with adb reverse).
  static const String _host = '10.0.2.2';

  // Keep in sync with PORT in Backend/config/.env
  static const int _port = 4000;

  static String get baseUrl => 'http://$_host:$_port/api/v1';

  // ── Request Header Constants ───────────────────────────────────────────────
  static const String clientTypeHeader = 'x-client-type';
  static const String clientTypeValue = 'mobile';

  // ── Auth Endpoints ─────────────────────────────────────────────────────────
  static String get register => '$baseUrl/register';
  static String get login => '$baseUrl/login';
  static String get userProfile => '$baseUrl/me';
  static String get updateProfile => '$baseUrl/me/update';
  static String get updatePassword => '$baseUrl/password/update';
  static String get forgotPassword => '$baseUrl/password/reset';

  // ── Donor Endpoints ────────────────────────────────────────────────────────
  static String get donorMe => '$baseUrl/donor/me';
  static String get submitDonorApplication => '$baseUrl/donors';
  static String get checkEligibility => '$baseUrl/check-eligibility';

  // ── Events & Schedules Endpoints ───────────────────────────────────────────
  static String get upcomingLettings => '$baseUrl/upcoming/lettings';
  static String get publicNewDonorEvent => '$baseUrl/letting-newDonor';

  // ── Resources & Announcements ──────────────────────────────────────────────
  static String get articles => '$baseUrl/articles';
  static String get announcements => '$baseUrl/announcements';

  // ── Notifications ──────────────────────────────────────────────────────────
  static String get notifications => '$baseUrl/notifications';
  static String get registerNotificationToken => '$baseUrl/notifications/check';
  static String markNotificationSeen(String id) => '$baseUrl/notifications/$id';
}
