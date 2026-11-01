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
  static String get selfRegister => '$baseUrl/self-register';
  static String get verifyClaim => '$baseUrl/verify-claim';
  static String get claimRecord => '$baseUrl/claim-record';
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

  // ── Staff Dashboard CRUD Endpoints ─────────────────────────────────────────
  // Donors
  static String get donors => '$baseUrl/donors';
  static String get staffDonorsDashboard => '$baseUrl/staff/donors/dashboard';
  static String get staffCreateDonor => '$baseUrl/staff/donor';
  static String get archivedDonors => '$baseUrl/donors/archived';
  static String donorById(String id) => '$baseUrl/donor/$id';
  static String softDeleteDonor(String id) => '$baseUrl/donor/$id/soft-delete';
  static String restoreDonor(String id) => '$baseUrl/donor/$id/restore';
  static String donorClaimToken(String id) => '$baseUrl/donor/$id/claim-token';
  static String donorScreeningStatus(String id) => '$baseUrl/donor/$id/screening-status';

  // Recipients / Patients
  static String get patients => '$baseUrl/patients';
  static String get staffPatientsDashboard => '$baseUrl/staff/patients/dashboard';
  static String get staffCreatePatient => '$baseUrl/staff/patient';
  static String get archivedPatients => '$baseUrl/patients/archived';
  static String patientById(String id) => '$baseUrl/patient/$id';
  static String softDeletePatient(String id) => '$baseUrl/patient/$id/soft-delete';
  static String restorePatient(String id) => '$baseUrl/patient/$id/restore';
  static String patientClaimToken(String id) => '$baseUrl/patient/$id/claim-token';

  // Requests
  static String get requests => '$baseUrl/requests';
  static String get archivedRequests => '$baseUrl/requests/archived';
  static String requestById(String id) => '$baseUrl/request/$id';
  static String softDeleteRequest(String id) => '$baseUrl/request/$id/soft-delete';
  static String restoreRequest(String id) => '$baseUrl/request/$id/restore';
}
