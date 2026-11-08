import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../models/patient_model.dart';
import '../../models/request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../auth/login_screen.dart';
import 'dialogs/donor_form_dialog.dart';
import 'dialogs/patient_form_dialog.dart';
import 'dialogs/request_form_dialog.dart';
import '../profile/edit_profile_screen.dart';
import '../../widgets/stacked_data_card.dart';
import '../../widgets/user_avatar.dart';
import 'staff_screening_appointments_screen.dart';
import 'pending_registrations_screen.dart';

/// Which section of the staff portal is currently open.
/// null = the card-grid dashboard (home).
enum StaffSection { donors, recipients, requests }

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// null => show dashboard cards, otherwise show that section's records.
  StaffSection? _section;

  // 0: Active, 1: Archived
  int _activeArchivedFilter = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    staffProvider.fetchDonors(isArchived: false);
    staffProvider.fetchDonors(isArchived: true);
    staffProvider.fetchPatients(isArchived: false);
    staffProvider.fetchPatients(isArchived: true);
    staffProvider.fetchRequests(isArchived: false);
    staffProvider.fetchRequests(isArchived: true);
  }

  Future<void> _handleRefresh() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final isArchived = _activeArchivedFilter == 1;
    switch (_section) {
      case StaffSection.donors:
        await staffProvider.fetchDonors(isArchived: isArchived);
        break;
      case StaffSection.recipients:
        await staffProvider.fetchPatients(isArchived: isArchived);
        break;
      case StaffSection.requests:
        await staffProvider.fetchRequests(isArchived: isArchived);
        break;
      case null:
        _loadAllData();
        break;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(dt);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NAVIGATION BETWEEN DASHBOARD <-> SECTION
  // ───────────────────────────────────────────────────────────────────────────

  void _openSection(StaffSection section) {
    _searchController.clear();
    setState(() {
      _section = section;
      _activeArchivedFilter = 0;
      _searchQuery = '';
    });
  }

  void _backToDashboard() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _section = null;
      _activeArchivedFilter = 0;
      _searchQuery = '';
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROFILE / SIGN OUT / NOTIFICATIONS
  // ───────────────────────────────────────────────────────────────────────────

  void _showProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No new notifications')),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CONFIRMATION DIALOG HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  void _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<bool> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await onConfirm();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Operation completed successfully' : 'Operation failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CLAIM TOKEN POPUP & SCREENING ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildClaimBadge(bool isClaimed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isClaimed ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isClaimed ? AppColors.success : AppColors.warning,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClaimed ? Icons.link : Icons.link_off,
            size: 11,
            color: isClaimed ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isClaimed ? 'Claimed / Linked' : 'Unclaimed',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isClaimed ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  void _showClaimTokenDialog({
    required String title,
    required String claimToken,
    required String recipientName,
    String? qrCodeData,
  }) {
    Uint8List? qrImageBytes;
    if (qrCodeData != null && qrCodeData.startsWith('data:image')) {
      try {
        final commaIdx = qrCodeData.indexOf(',');
        if (commaIdx != -1) {
          qrImageBytes = base64Decode(qrCodeData.substring(commaIdx + 1));
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Provide this scannable QR Code or 16-character Token to $recipientName to activate their mobile profile:',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // QR Code Render Block
              if (qrImageBytes != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                  ),
                  child: Image.memory(
                    qrImageBytes,
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.qr_code_2, size: 70, color: AppColors.primaryNavy),
                        SizedBox(height: 6),
                        Text(
                          'Scannable QR Ready',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Token Display Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBlue),
                ),
                child: Column(
                  children: [
                    const Text('CLAIM TOKEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    SelectableText(
                      claimToken,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _generateDonorClaimToken(DonorModel donor) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final token = await staffProvider.generateDonorClaimToken(donor.id);
    if (token != null && mounted) {
      _showClaimTokenDialog(
        title: 'Donor QR & Claim Token',
        claimToken: token,
        qrCodeData: staffProvider.lastCreatedQrCodeData,
        recipientName: donor.displayName,
      );
    }
  }

  void _generatePatientClaimToken(PatientModel patient) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final token = await staffProvider.generatePatientClaimToken(patient.id);
    if (token != null && mounted) {
      _showClaimTokenDialog(
        title: 'Patient QR & Claim Token',
        claimToken: token,
        qrCodeData: staffProvider.lastCreatedQrCodeData,
        recipientName: patient.motherName.isNotEmpty ? patient.motherName : patient.name,
      );
    }
  }

  void _openUpdateScreeningDialog(DonorModel donor) {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    String selectedStatus = donor.eligibility;
    final notesController = TextEditingController();

    final allowedStatuses = [
      'Pending Review',
      'For Laboratory Verification',
      'For Medical Assessment',
      'Eligible',
      'Temporarily Deferred',
      'Not Eligible'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Review Screening Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Screening Status *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: allowedStatuses.contains(selectedStatus) ? selectedStatus : 'Pending Review',
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: allowedStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setDialogState(() => selectedStatus = v!),
              ),
              const SizedBox(height: 14),
              const Text('Review Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter clinical observations or laboratory remarks...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await staffProvider.updateDonorScreeningStatus(
                  donor.id,
                  selectedStatus,
                  reviewNotes: notesController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Status updated to $selectedStatus' : 'Update failed'),
                      backgroundColor: ok ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DONOR MODALS & ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  void _openDonorDialog({DonorModel? donor}) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DonorFormDialog(
        initialDonor: donor,
        onSave: (data) async {
          if (donor == null) {
            return await staffProvider.createDonor(data);
          } else {
            return await staffProvider.updateDonor(donor.id, data);
          }
        },
      ),
    );

    if (donor == null && staffProvider.lastCreatedClaimToken != null && mounted) {
      final token = staffProvider.lastCreatedClaimToken!;
      _showClaimTokenDialog(
        title: 'Donor Record Created',
        claimToken: token,
        qrCodeData: staffProvider.lastCreatedQrCodeData,
        recipientName: 'the donor',
      );
    }
  }

  void _archiveDonor(DonorModel donor) {
    _confirmAction(
      title: 'Archive Donor Record',
      message: 'Are you sure you want to move ${donor.displayName} to the archive? You can restore it later.',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).softDeleteDonor(donor.id),
    );
  }

  void _restoreDonor(DonorModel donor) {
    _confirmAction(
      title: 'Restore Donor Record',
      message: 'Restore ${donor.displayName} back to active donor records?',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primaryNavy,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).restoreDonor(donor.id),
    );
  }

  void _deleteDonorPermanently(DonorModel donor) {
    _confirmAction(
      title: 'Delete Donor Permanently',
      message: 'This will permanently remove ${donor.displayName}. This action cannot be undone.',
      confirmLabel: 'Delete Forever',
      confirmColor: AppColors.error,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).deleteDonorPermanently(donor.id),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PATIENT / RECIPIENT MODALS & ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  void _openPatientDialog({PatientModel? patient}) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PatientFormDialog(
        initialPatient: patient,
        availablePatients: staffProvider.activePatients,
        onSave: (data) async {
          final targetId = data['_id'] as String? ?? patient?.id;
          if (targetId != null && targetId.isNotEmpty) {
            return await staffProvider.updatePatient(targetId, data);
          } else {
            return await staffProvider.createPatient(data);
          }
        },
      ),
    );

    if (patient == null && staffProvider.lastCreatedClaimToken != null && mounted) {
      final token = staffProvider.lastCreatedClaimToken!;
      _showClaimTokenDialog(
        title: 'Recipient Record Created',
        claimToken: token,
        qrCodeData: staffProvider.lastCreatedQrCodeData,
        recipientName: 'the mother/guardian',
      );
    }
  }

  void _archivePatient(PatientModel patient) {
    _confirmAction(
      title: 'Archive Recipient Record',
      message: 'Are you sure you want to archive ${patient.name}? The record will be stored in the archive.',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).softDeletePatient(patient.id),
    );
  }

  void _restorePatient(PatientModel patient) {
    _confirmAction(
      title: 'Restore Recipient Record',
      message: 'Restore ${patient.name} back to active recipient records?',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primaryNavy,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).restorePatient(patient.id),
    );
  }

  void _deletePatientPermanently(PatientModel patient) {
    _confirmAction(
      title: 'Delete Recipient Permanently',
      message: 'Are you sure you want to permanently delete ${patient.name}? This action cannot be reversed.',
      confirmLabel: 'Delete Forever',
      confirmColor: AppColors.error,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).deletePatientPermanently(patient.id),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REQUEST MODALS & ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  void _openRequestDialog({RequestModel? request}) {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RequestFormDialog(
        initialRequest: request,
        availablePatients: staffProvider.activePatients,
        onSave: (data) async {
          if (request == null) {
            return await staffProvider.createRequest(data);
          } else {
            return await staffProvider.updateRequest(request.id, data);
          }
        },
      ),
    );
  }

  void _archiveRequest(RequestModel req) {
    _confirmAction(
      title: 'Archive Milk Request',
      message: 'Are you sure you want to move this request for ${req.patientName.isNotEmpty ? req.patientName : "patient"} to the archive?',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).softDeleteRequest(req.id),
    );
  }

  void _restoreRequest(RequestModel req) {
    _confirmAction(
      title: 'Restore Milk Request',
      message: 'Restore this milk request back to active requests?',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primaryNavy,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).restoreRequest(req.id),
    );
  }

  void _deleteRequestPermanently(RequestModel req) {
    _confirmAction(
      title: 'Delete Request Permanently',
      message: 'This will permanently remove this milk request record. This action cannot be undone.',
      confirmLabel: 'Delete Forever',
      confirmColor: AppColors.error,
      onConfirm: () => Provider.of<StaffProvider>(context, listen: false).deleteRequestPermanently(req.id),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHARED SMALL WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String text, {Color? bg, Color? fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? AppColors.softBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg ?? AppColors.primaryNavy,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open, size: 48, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ───────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.accentPink,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.volunteer_activism, color: AppColors.accentPink, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MilkLink Staff Portal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Pasig Human Milk Bank',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
          tooltip: 'Notifications',
          onPressed: _showNotifications,
        ),
        PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'profile') {
              _showProfile();
            } else if (val == 'sign_out') {
              _signOut();
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Builder(builder: (ctx) {
              final user = Provider.of<AuthProvider>(ctx).user;
              return UserAvatar(
                radius: 17,
                avatarUrl: user?.avatarUrl,
                initial: user?.name.first.isNotEmpty == true ? user!.name.first : 'S',
                backgroundColor: Colors.white,
                textColor: AppColors.primaryNavy,
              );
            }),
          ),
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: AppColors.primaryNavy),
                  SizedBox(width: 10),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sign_out',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: AppColors.error),
                  SizedBox(width: 10),
                  Text('Sign Out', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DASHBOARD HOME (card grid)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? count,
  }) {
    return Material(
      color: AppColors.accentPink,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 54, color: Colors.white),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (count != null)
              Positioned(
                top: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome(StaffProvider staffProvider) {
    return RefreshIndicator(
      color: AppColors.accentPink,
      onRefresh: () async => _loadAllData(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const Center(
            child: Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.08,
            children: [
              _buildDashboardCard(
                icon: Icons.favorite,
                label: 'Donor Records',
                count: staffProvider.activeDonors.length,
                onTap: () => _openSection(StaffSection.donors),
              ),
              _buildDashboardCard(
                icon: Icons.child_care,
                label: 'Recipient Records',
                count: staffProvider.activePatients.length,
                onTap: () => _openSection(StaffSection.recipients),
              ),
              _buildDashboardCard(
                icon: Icons.assignment,
                label: 'Milk Requests',
                count: staffProvider.activeRequests.length,
                onTap: () => _openSection(StaffSection.requests),
              ),
              _buildDashboardCard(
                icon: Icons.person_search,
                label: 'Pending Online Registrations',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PendingRegistrationsScreen()),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.calendar_month,
                label: 'Screening Clinic',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StaffScreeningAppointmentsScreen()),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                onTap: () => _showComingSoon('Inventory'),
              ),
              _buildDashboardCard(
                icon: Icons.bar_chart,
                label: 'Metrics',
                onTap: () => _showComingSoon('Metrics'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RECORD LISTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDonorsTab(StaffProvider staffProvider) {
    final isArchived = _activeArchivedFilter == 1;
    var list = isArchived ? staffProvider.archivedDonors : staffProvider.activeDonors;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        final name = d.displayName.toLowerCase();
        final type = d.donorType.toLowerCase();
        final contact = d.contactNumber?.toLowerCase() ?? '';
        final brgy = d.homeAddress.brgy.toLowerCase();
        return name.contains(q) || type.contains(q) || contact.contains(q) || brgy.contains(q);
      }).toList();
    }

    if (list.isEmpty) {
      return _buildEmptyState(
        isArchived ? 'No archived donor records found.' : 'No active donor records found.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final donor = list[idx];
        final donorName = donor.displayName;

        Color badgeBg = AppColors.softBlue;
        Color badgeFg = AppColors.primaryNavy;
        if (donor.eligibility.toLowerCase() == 'eligible') {
          badgeBg = AppColors.success.withValues(alpha: 0.15);
          badgeFg = AppColors.success;
        } else if (donor.eligibility.toLowerCase() == 'not eligible' ||
            donor.eligibility.toLowerCase() == 'ineligible') {
          badgeBg = AppColors.error.withValues(alpha: 0.15);
          badgeFg = AppColors.error;
        }

        return StackedDataCard(
          title: donorName,
          subtitle: donor.isDeleted
              ? 'Archived on ${_formatDate(donor.deletedAt)}'
              : 'Registered ${_formatDate(donor.createdAt)}',
          isArchived: donor.isDeleted,
          statusBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildClaimBadge(donor.isClaimed),
              _buildStatusBadge(donor.eligibility, bg: badgeBg, fg: badgeFg),
            ],
          ),
          fields: [
            DataFieldItem(label: 'Donor Type', value: donor.donorType),
            DataFieldItem(label: 'Contact Number', value: donor.contactNumber ?? '—'),
            DataFieldItem(
              label: 'Eligibility Status',
              value: donor.eligibility,
              valueColor: badgeFg,
            ),
            DataFieldItem(
              label: 'Claim Status',
              value: donor.claimStatus,
              valueColor: donor.isClaimed ? AppColors.success : AppColors.warning,
            ),
            DataFieldItem(label: 'Home Address', value: donor.homeAddress.fullAddress),
            DataFieldItem(label: 'Birthday', value: _formatDate(donor.birthday)),
            DataFieldItem(label: 'Occupation', value: donor.occupation ?? '—'),
            DataFieldItem(label: 'Responsible Staff', value: donor.staffName ?? 'MilkLink Staff'),
            DataFieldItem(label: 'Verified Profile', value: donor.verified ? 'Yes (Verified)' : 'No (Pending)'),
            DataFieldItem(
              label: 'Baby / Children',
              value: donor.children.isNotEmpty
                  ? donor.children.map((c) {
                      final ageStr = c.ageValue != null ? ' (${c.ageValue} ${c.ageUnit ?? 'weeks'})' : '';
                      return '${c.name}$ageStr';
                    }).join(', ')
                  : 'None listed',
            ),
          ],
          onEdit: donor.isDeleted ? null : () => _openDonorDialog(donor: donor),
          onArchive: donor.isDeleted ? null : () => _archiveDonor(donor),
          onRestore: donor.isDeleted ? () => _restoreDonor(donor) : null,
          onDelete: () => _deleteDonorPermanently(donor),
          onGenerateClaimToken: donor.isDeleted || donor.isClaimed ? null : () => _generateDonorClaimToken(donor),
          onUpdateStatus: donor.isDeleted ? null : () => _openUpdateScreeningDialog(donor),
          statusActionLabel: 'Review Screening Status',
        );
      },
    );
  }

  Widget _buildPatientsTab(StaffProvider staffProvider) {
    final isArchived = _activeArchivedFilter == 1;
    var list = isArchived ? staffProvider.archivedPatients : staffProvider.activePatients;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final name = p.name.toLowerCase();
        final mother = p.motherName.toLowerCase();
        final type = p.patientType.toLowerCase();
        final phone = p.phone.toLowerCase();
        return name.contains(q) || mother.contains(q) || type.contains(q) || phone.contains(q);
      }).toList();
    }

    if (list.isEmpty) {
      return _buildEmptyState(
        isArchived ? 'No archived recipient records found.' : 'No active recipient records found.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final patient = list[idx];

        return StackedDataCard(
          title: patient.name,
          subtitle: patient.isDeleted
              ? 'Archived on ${_formatDate(patient.deletedAt)}'
              : 'Admitted on ${_formatDate(patient.admissionDate)}',
          isArchived: patient.isDeleted,
          statusBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildClaimBadge(patient.isClaimed),
              _buildStatusBadge(
                patient.patientType,
                bg: patient.patientType == 'In-patient' ? AppColors.softBlue : AppColors.softPink,
                fg: patient.patientType == 'In-patient' ? AppColors.primaryNavy : AppColors.accentPink,
              ),
            ],
          ),
          fields: [
            DataFieldItem(label: 'Patient Type', value: patient.patientType),
            DataFieldItem(label: "Mother's Name", value: patient.motherName),
            DataFieldItem(label: 'Contact Phone', value: patient.phone),
            DataFieldItem(
              label: 'Claim Status',
              value: patient.claimStatus,
              valueColor: patient.isClaimed ? AppColors.success : AppColors.warning,
            ),
            DataFieldItem(label: 'Home Address', value: patient.homeAddress.fullAddress),
            DataFieldItem(label: 'Age', value: '${patient.age} days old'),
            DataFieldItem(label: 'AOG (Weeks)', value: '${patient.aog} weeks'),
            DataFieldItem(label: 'Admission Date', value: _formatDate(patient.admissionDate)),
            DataFieldItem(label: 'Assigned Staff', value: patient.staffName ?? 'MilkLink Staff'),
          ],
          onEdit: patient.isDeleted ? null : () => _openPatientDialog(patient: patient),
          onArchive: patient.isDeleted ? null : () => _archivePatient(patient),
          onRestore: patient.isDeleted ? () => _restorePatient(patient) : null,
          onDelete: () => _deletePatientPermanently(patient),
          onGenerateClaimToken: patient.isDeleted || patient.isClaimed ? null : () => _generatePatientClaimToken(patient),
        );
      },
    );
  }

  Widget _buildRequestsTab(StaffProvider staffProvider) {
    final isArchived = _activeArchivedFilter == 1;
    var list = isArchived ? staffProvider.archivedRequests : staffProvider.activeRequests;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        final pName = r.patientName.toLowerCase();
        final status = r.status.toLowerCase();
        final physician = r.doctor.toLowerCase();
        final hospital = r.hospital.toLowerCase();
        return pName.contains(q) || status.contains(q) || physician.contains(q) || hospital.contains(q);
      }).toList();
    }

    if (list.isEmpty) {
      return _buildEmptyState(
        isArchived ? 'No archived milk requests found.' : 'No active milk requests found.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final req = list[idx];
        final patientName = req.patientName.isNotEmpty == true
            ? req.patientName
            : 'Recipient #${req.id.length > 6 ? req.id.substring(req.id.length - 6) : req.id}';

        Color stBg = AppColors.softBlue;
        Color stFg = AppColors.primaryNavy;
        switch (req.status.toLowerCase()) {
          case 'dispensed':
          case 'completed':
            stBg = AppColors.success.withValues(alpha: 0.15);
            stFg = AppColors.success;
            break;
          case 'approved':
            stBg = AppColors.primaryBlue.withValues(alpha: 0.15);
            stFg = AppColors.primaryBlue;
            break;
          case 'declined':
          case 'rejected':
            stBg = AppColors.error.withValues(alpha: 0.15);
            stFg = AppColors.error;
            break;
          case 'pending':
          default:
            stBg = AppColors.warning.withValues(alpha: 0.15);
            stFg = AppColors.warning;
            break;
        }

        return StackedDataCard(
          title: patientName,
          subtitle: req.isDeleted
              ? 'Archived on ${_formatDate(req.deletedAt)}'
              : 'Requested on ${_formatDate(req.date)}',
          isArchived: req.isDeleted,
          statusBadge: _buildStatusBadge(req.status, bg: stBg, fg: stFg),
          fields: [
            DataFieldItem(label: 'Status', value: req.status, valueColor: stFg),
            DataFieldItem(label: 'Volume Needed', value: '${req.volume.toStringAsFixed(0)} mL (${req.days} days)'),
            DataFieldItem(label: 'Patient Type', value: req.patientType),
            DataFieldItem(label: 'Diagnosis', value: req.diagnosis),
            DataFieldItem(label: 'Reason for Need', value: req.reason),
            DataFieldItem(label: 'Physician', value: req.doctor),
            DataFieldItem(
              label: 'Hospital / Dept',
              value: '${req.hospital}${req.department?.isNotEmpty == true ? " (${req.department})" : ""}',
            ),
            DataFieldItem(label: 'Request Date', value: _formatDate(req.date)),
            DataFieldItem(label: 'Requested By', value: req.requestedByName ?? 'MilkLink Staff'),
          ],
          onEdit: req.isDeleted ? null : () => _openRequestDialog(request: req),
          onArchive: req.isDeleted ? null : () => _archiveRequest(req),
          onRestore: req.isDeleted ? () => _restoreRequest(req) : null,
          onDelete: () => _deleteRequestPermanently(req),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION VIEW (records screen after tapping a dashboard card)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedColor : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? selectedColor : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionView(StaffProvider staffProvider) {
    final section = _section!;

    late final String title;
    late final int activeCount;
    late final int archivedCount;
    switch (section) {
      case StaffSection.donors:
        title = 'Donor Records';
        activeCount = staffProvider.activeDonors.length;
        archivedCount = staffProvider.archivedDonors.length;
        break;
      case StaffSection.recipients:
        title = 'Recipient Records';
        activeCount = staffProvider.activePatients.length;
        archivedCount = staffProvider.archivedPatients.length;
        break;
      case StaffSection.requests:
        title = 'Milk Requests';
        activeCount = staffProvider.activeRequests.length;
        archivedCount = staffProvider.archivedRequests.length;
        break;
    }

    Widget content;
    switch (section) {
      case StaffSection.donors:
        content = _buildDonorsTab(staffProvider);
        break;
      case StaffSection.recipients:
        content = _buildPatientsTab(staffProvider);
        break;
      case StaffSection.requests:
        content = _buildRequestsTab(staffProvider);
        break;
    }

    return Column(
      children: [
        // Section header with back button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.accentPink),
                tooltip: 'Back to dashboard',
                onPressed: _backToDashboard,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.accentPink),
                tooltip: 'Refresh',
                onPressed: _handleRefresh,
              ),
            ],
          ),
        ),

        // Active / Archived pills + search
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  _buildFilterPill(
                    label: 'Active Records',
                    count: activeCount,
                    selected: _activeArchivedFilter == 0,
                    selectedColor: AppColors.primaryNavy,
                    onTap: () => setState(() => _activeArchivedFilter = 0),
                  ),
                  const SizedBox(width: 10),
                  _buildFilterPill(
                    label: 'Archived Records',
                    count: archivedCount,
                    selected: _activeArchivedFilter == 1,
                    selectedColor: AppColors.warning,
                    onTap: () => setState(() => _activeArchivedFilter = 1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),

        // Records list with pull-to-refresh
        Expanded(
          child: staffProvider.status == StaffLoadingStatus.loading &&
                  activeCount == 0 &&
                  archivedCount == 0
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryNavy),
                )
              : RefreshIndicator(
                  color: AppColors.primaryNavy,
                  onRefresh: _handleRefresh,
                  child: content,
                ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MAIN BUILD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);

    // FAB only inside a section and only on the Active filter.
    Widget? fab;
    if (_section != null && _activeArchivedFilter == 0) {
      late final String fabLabel;
      late final VoidCallback onFabPressed;
      switch (_section!) {
        case StaffSection.donors:
          fabLabel = 'New Donor';
          onFabPressed = () => _openDonorDialog();
          break;
        case StaffSection.recipients:
          fabLabel = 'New Recipient';
          onFabPressed = () => _openPatientDialog();
          break;
        case StaffSection.requests:
          fabLabel = 'New Request';
          onFabPressed = () => _openRequestDialog();
          break;
      }
      fab = FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          fabLabel,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: onFabPressed,
      );
    }

    return PopScope(
  canPop: _section == null,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    setState(() => _section = null);
  },
  child: Scaffold(
    backgroundColor: AppColors.background,
    appBar: _buildAppBar(),
    body: _section == null
        ? _buildDashboardHome(staffProvider)
        : _buildSectionView(staffProvider),
    floatingActionButton: fab,
  ),
);
  }
}
