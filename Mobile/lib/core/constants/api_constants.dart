class ApiConstants {
  // ── Connection ─────────────────────────────────────────────────────────────
  // Change to '10.0.2.2' if using an Android Emulator, or your computer's local Wi-Fi IP for physical devices.
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
  static String get linkDonorRecord => '$baseUrl/user/link-donor';
  static String get login => '$baseUrl/login';
  static String get userProfile => '$baseUrl/me';
  static String get updateProfile => '$baseUrl/me/update';
  static String get updatePassword => '$baseUrl/password/update';
  static String get forgotPassword => '$baseUrl/password/reset';

  // ── Screening Appointments Endpoints ─────────────────────────────────────────
  static String get screeningSlots => '$baseUrl/screening/slots';
  static String get bookScreeningAppointment => '$baseUrl/screening/book';
  static String get myScreeningAppointments => '$baseUrl/screening/my-appointments';
  static String cancelScreeningAppointment(String id) => '$baseUrl/screening/appointment/$id/cancel';
  static String rescheduleScreeningAppointment(String id) => '$baseUrl/screening/appointment/$id/reschedule';
  static String get staffScreeningAppointments => '$baseUrl/staff/screening/appointments';
  static String staffAppointmentStatus(String id) => '$baseUrl/staff/screening/appointment/$id/status';
  static String staffCompleteScreening(String id) => '$baseUrl/staff/screening/appointment/$id/complete-screening';

  // ── Donor Endpoints ────────────────────────────────────────────────────────
  static String get donorRegister => '$baseUrl/donor/register';
  static String get donorSearchReturning => '$baseUrl/donor/search-returning';
  static String get donorMe => '$baseUrl/donor/me';
  static String get submitDonorApplication => '$baseUrl/donor/register';
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
  static String get staffPendingRegistrations => '$baseUrl/staff/pending-registrations';
  static String staffLinkUserToDonor(String userId) => '$baseUrl/staff/user/$userId/link-donor';
  static String staffCreateDonorForUser(String userId) => '$baseUrl/staff/user/$userId/create-donor';
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

  // ── Admin Portal Endpoints ────────────────────────────────────────────────
  static String get adminUsers => '$baseUrl/admin/users';
  static String get inventories => '$baseUrl/inventories';
  static String get pickups => '$baseUrl/staff/pickups';
  static String get schedules => '$baseUrl/schedules';
  static String get adminMetrics => '$baseUrl/metrics';
}
