import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../models/admin/admin_models.dart';
import '../../models/patient_model.dart';
import '../../providers/admin/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../widgets/dashboard_grid_scaffold.dart';
import '../../widgets/record_card.dart';
import '../../widgets/records_list_scaffold.dart';
import '../../widgets/admin/admin_summary_card.dart';
import '../auth/login_screen.dart';
import '../staff/dialogs/donor_form_dialog.dart';
import '../staff/dialogs/patient_form_dialog.dart';
import '../schedules/schedules_screen.dart';
import '../inventory/inventory_screen.dart';
import '../accounts/account_management_screen.dart';
import '../content/content_management_screen.dart';
import '../requests/milk_requests_screen.dart';
import '../metrics/metrics_dashboard_screen.dart';
import '../../widgets/user_avatar.dart';
import '../profile/edit_profile_screen.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminModule? _selectedModule;
  final TextEditingController _recordSearchController = TextEditingController();
  String _recordSearch = '';
  int _activeArchivedFilter = 0;

  @override
  void dispose() {
    _recordSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
    });
  }

  void _loadAdminData() {
    context.read<AdminProvider>().refresh();
    final staffProvider = context.read<StaffProvider>();
    staffProvider.fetchDonors();
    staffProvider.fetchDonors(isArchived: true);
    staffProvider.fetchPatients();
    staffProvider.fetchPatients(isArchived: true);
    staffProvider.fetchRequests();
    staffProvider.fetchRequests(isArchived: true);
  }

  Future<void> _handleRefresh() async {
    final adminProvider = context.read<AdminProvider>();
    final staffProvider = context.read<StaffProvider>();
    await Future.wait([
      adminProvider.refresh(),
      staffProvider.fetchDonors(),
      staffProvider.fetchDonors(isArchived: true),
      staffProvider.fetchPatients(),
      staffProvider.fetchPatients(isArchived: true),
      staffProvider.fetchRequests(),
      staffProvider.fetchRequests(isArchived: true),
    ]);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  Future<void> _openDonorDialog({DonorModel? donor}) async {
    final staffProvider = context.read<StaffProvider>();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DonorFormDialog(
        initialDonor: donor,
        onSave: (data) => donor == null
            ? staffProvider.createDonor(data)
            : staffProvider.updateDonor(donor.id, data),
      ),
    );
    if (mounted &&
        donor == null &&
        staffProvider.lastCreatedClaimToken != null) {
      _showMessage('Donor record created successfully.');
    }
  }

  Future<void> _openPatientDialog({PatientModel? patient}) async {
    final staffProvider = context.read<StaffProvider>();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PatientFormDialog(
        initialPatient: patient,
        availablePatients: staffProvider.activePatients,
        onSave: (data) {
          final targetId = data['_id'] as String? ?? patient?.id;
          return targetId != null && targetId.isNotEmpty
              ? staffProvider.updatePatient(targetId, data)
              : staffProvider.createPatient(data);
        },
      ),
    );
    if (mounted &&
        patient == null &&
        staffProvider.lastCreatedClaimToken != null) {
      _showMessage('Recipient record created successfully.');
    }
  }

  void _generateDonorClaimToken(DonorModel donor) async {
    final staffProvider = context.read<StaffProvider>();
    final token = await staffProvider.generateDonorClaimToken(donor.id);
    if (token != null && mounted) {
      _showMessage('Claim token generated: $token');
    }
  }

  void _generatePatientClaimToken(PatientModel patient) async {
    final staffProvider = context.read<StaffProvider>();
    final token = await staffProvider.generatePatientClaimToken(patient.id);
    if (token != null && mounted) {
      _showMessage('Claim token generated: $token');
    }
  }

  Widget _buildClaimBadge(bool isClaimed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isClaimed
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
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

  Widget _buildEligibilityBadge(String eligibility) {
    Color fg = AppColors.primaryNavy;
    if (eligibility.toLowerCase() == 'eligible') {
      fg = AppColors.success;
    } else if (eligibility.toLowerCase() == 'not eligible' ||
        eligibility.toLowerCase() == 'ineligible') {
      fg = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        eligibility,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  void _openDonorStatusDialog(DonorModel donor) {
    final staffProvider = context.read<StaffProvider>();
    var selectedStatus = donor.eligibility;
    final notesController = TextEditingController();
    const statuses = [
      'Pending Review',
      'For Laboratory Verification',
      'For Medical Assessment',
      'Eligible',
      'Temporarily Deferred',
      'Not Eligible',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: const Text('Edit Donor Status'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eligibility Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: statuses.contains(selectedStatus)
                        ? selectedStatus
                        : statuses.first,
                    items: statuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Review notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await staffProvider.updateDonorScreeningStatus(
                  donor.id,
                  selectedStatus,
                  reviewNotes: notesController.text.trim(),
                );
                if (mounted) {
                  _showMessage(
                    success
                        ? 'Donor status updated.'
                        : 'Unable to update donor status.',
                    isError: !success,
                  );
                }
                notesController.dispose();
              },
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPatientStatusDialog(PatientModel patient) {
    final staffProvider = context.read<StaffProvider>();
    var selectedStatus = patient.patientType;
    const statuses = ['Inpatient', 'Outpatient'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: const Text('Edit Recipient Status'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: DropdownButtonFormField<String>(
                initialValue: statuses.contains(selectedStatus)
                    ? selectedStatus
                    : statuses.first,
                items: statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedStatus = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Recipient status',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final payload = patient.toJson()
                  ..['patientType'] = selectedStatus;
                final success =
                    await staffProvider.updatePatient(patient.id, payload);
                if (mounted) {
                  _showMessage(
                    success
                        ? 'Recipient status updated.'
                        : 'Unable to update recipient status.',
                    isError: !success,
                  );
                }
              },
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRecordAction({
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
    required Future<bool> Function() action,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Text(message),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await action();
              if (mounted) {
                _showMessage(
                  success ? '$actionLabel completed.' : '$actionLabel failed.',
                  isError: !success,
                );
              }
            },
            child:
                Text(actionLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _selectModule(AdminModule module) {
    setState(() => _selectedModule = module);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminProvider, StaffProvider>(
      builder: (context, provider, staffProvider, _) {
        if (_selectedModule == null) {
          final items = AdminModule.values.map((module) {
            int count = 0;
            if (module == AdminModule.donors) {
              count = staffProvider.activeDonors.isNotEmpty
                  ? staffProvider.activeDonors.length
                  : ((provider.data.metrics['metrics'] is Map)
                      ? (provider.data.metrics['metrics']['totalDonors'] as num? ?? 0).toInt()
                      : 0);
            } else if (module == AdminModule.recipients) {
              count = staffProvider.activePatients.isNotEmpty
                  ? staffProvider.activePatients.length
                  : ((provider.data.metrics['metrics'] is Map)
                      ? (provider.data.metrics['metrics']['totalRecipients'] as num? ?? 0).toInt()
                      : 0);
            } else if (module == AdminModule.requests) {
              count = staffProvider.activeRequests.length;
            } else {
              final records = provider.data.recordsFor(module);
              count = records.length;
            }

            return DashboardItem(
              label: module.label,
              icon: module.icon,
              badgeCount: count > 0 ? count : null,
              onTap: () => _selectModule(module),
            );
          }).toList();

          num totalStockMl = 0;
          for (final item in provider.data.inventory) {
            final isPasteurized = item['isPasteurized'] == true;
            if (isPasteurized) {
              final bottles = (item['availableBottles'] as num?)?.toDouble() ?? 0;
              final bType = (item['bottleType'] as num?)?.toDouble() ?? 0;
              final vol = (item['volume'] as num?)?.toDouble() ?? 0;
              totalStockMl += (bottles > 0 && bType > 0) ? (bottles * bType) : vol;
            } else {
              final vol = (item['volume'] as num?)?.toDouble() ?? 0;
              totalStockMl += vol;
            }
          }

          final pendingRequests = staffProvider.activeRequests
              .where((r) => r.status.toLowerCase() == 'pending')
              .length;

          final stats = [
            DashboardStatItem(
              label: 'Total Donors',
              value: staffProvider.activeDonors.isNotEmpty
                  ? staffProvider.activeDonors.length
                  : ((provider.data.metrics['metrics'] is Map)
                      ? (provider.data.metrics['metrics']['totalDonors'] as num? ?? 0)
                      : 0),
              icon: Icons.favorite,
            ),
            DashboardStatItem(
              label: 'Total Recipients',
              value: staffProvider.activePatients.isNotEmpty
                  ? staffProvider.activePatients.length
                  : ((provider.data.metrics['metrics'] is Map)
                      ? (provider.data.metrics['metrics']['totalRecipients'] as num? ?? 0)
                      : 0),
              icon: Icons.child_care,
            ),
            DashboardStatItem(
              label: 'Pending Requests',
              value: pendingRequests,
              icon: Icons.assignment_outlined,
            ),
            DashboardStatItem(
              label: 'Milk Inventory',
              value: totalStockMl,
              unit: 'ml',
              icon: Icons.inventory_2_outlined,
            ),
          ];

          return DashboardGridScaffold(
            title: 'Dashboard',
            items: items,
            stats: stats,
            isStatsLoading: provider.status == AdminLoadStatus.loading && provider.data.inventory.isEmpty,
            statsError: provider.status == AdminLoadStatus.error ? provider.errorMessage : null,
            onRetryStats: _handleRefresh,
            onRefresh: _handleRefresh,
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
                icon: const Icon(Icons.notifications_none, color: AppColors.primaryNavy),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'profile') {
                    _showProfile();
                  } else if (val == 'sign_out') {
                    _logout();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, left: 4),
                  child: Builder(builder: (ctx) {
                    final user = Provider.of<AuthProvider>(ctx).user;
                    return UserAvatar(
                      radius: 17,
                      avatarUrl: user?.avatarUrl,
                      initial: user?.name.first.isNotEmpty == true ? user!.name.first : 'A',
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

        if (_selectedModule == AdminModule.donors) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              setState(() {
                _selectedModule = null;
                _recordSearchController.clear();
                _recordSearch = '';
                _activeArchivedFilter = 0;
              });
            },
            child: _buildAdminDonorsView(staffProvider),
          );
        }

        if (_selectedModule == AdminModule.recipients) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              setState(() {
                _selectedModule = null;
                _recordSearchController.clear();
                _recordSearch = '';
                _activeArchivedFilter = 0;
              });
            },
            child: _buildAdminRecipientsView(staffProvider),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: _buildModule(provider, staffProvider, _selectedModule!),
          ),
          floatingActionButton: _buildAdminFab(),
        );
      },
    );
  }

  Widget? _buildAdminFab() {
    return null;
  }

  Widget _buildModule(
    AdminProvider provider,
    StaffProvider staffProvider,
    AdminModule module,
  ) {
    if (module == AdminModule.schedules) {
      return SchedulesScreen(
        onBack: () {
          setState(() => _selectedModule = null);
          _loadAdminData();
        },
      );
    }
    if (module == AdminModule.inventory) {
      return const InventoryScreen();
    }
    if (module == AdminModule.accounts) {
      return const AccountManagementScreen();
    }
    if (module == AdminModule.content) {
      return ContentManagementScreen(
        onBack: () {
          setState(() => _selectedModule = null);
          _loadAdminData();
        },
      );
    }
    if (module == AdminModule.requests) {
      return MilkRequestsScreen(
        onBack: () {
          setState(() => _selectedModule = null);
          _loadAdminData();
        },
      );
    }
    if (module == AdminModule.metrics) {
      return MetricsDashboardScreen(
        onBack: () {
          setState(() => _selectedModule = null);
          _loadAdminData();
        },
      );
    }

    final records = provider.data.recordsFor(module);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedModule = null),
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              module.label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        AdminSummaryCard(
          module: module,
          records: records,
          metrics: provider.data.metrics,
        ),
      ],
    );
  }

  List<dynamic> _filterStaffRecords(List<dynamic> source, String query) {
    if (query.isEmpty) return source;
    final q = query.toLowerCase();
    return source.where((record) {
      if (record is DonorModel) {
        return record.displayName.toLowerCase().contains(q) ||
            record.donorType.toLowerCase().contains(q) ||
            (record.contactNumber?.toLowerCase().contains(q) ?? false) ||
            record.homeAddress.brgy.toLowerCase().contains(q);
      } else if (record is PatientModel) {
        return record.name.toLowerCase().contains(q) ||
            record.motherName.toLowerCase().contains(q) ||
            record.patientType.toLowerCase().contains(q) ||
            record.phone.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Widget _buildAdminDonorsView(StaffProvider staffProvider) {
    final isArchived = _activeArchivedFilter == 1;
    final source =
        isArchived ? staffProvider.archivedDonors : staffProvider.activeDonors;
    final list = _filterStaffRecords(source, _recordSearch);

    return RecordsListScaffold(
      title: 'Donor Records',
      onBack: () => setState(() {
        _selectedModule = null;
        _recordSearchController.clear();
        _recordSearch = '';
        _activeArchivedFilter = 0;
      }),
      onRefresh: _handleRefresh,
      searchController: _recordSearchController,
      searchQuery: _recordSearch,
      onSearchChanged: (val) => setState(() => _recordSearch = val.trim()),
      searchHint: 'Search records...',
      activeCount: staffProvider.activeDonors.length,
      archivedCount: staffProvider.archivedDonors.length,
      selectedFilter: _activeArchivedFilter,
      onFilterChanged: (filter) =>
          setState(() => _activeArchivedFilter = filter),
      isLoading: staffProvider.status == StaffLoadingStatus.loading &&
          staffProvider.activeDonors.isEmpty &&
          staffProvider.archivedDonors.isEmpty,
      errorMessage: staffProvider.status == StaffLoadingStatus.error
          ? staffProvider.errorMessage
          : null,
      fabLabel: 'New Donor',
      onFabPressed: () => _openDonorDialog(),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final donor = list[idx] as DonorModel;
        return RecordCard(
          title: donor.displayName,
          statusChipText: donor.donorType,
          isArchived: isArchived,
          infoLines: [
            RecordInfoLine(
              icon: Icons.calendar_today_outlined,
              text: donor.isDeleted
                  ? 'Archived on ${_formatDate(donor.deletedAt)}'
                  : 'Registered ${_formatDate(donor.createdAt)}',
            ),
            RecordInfoLine(
              icon: Icons.person_outline,
              text: donor.donorType,
            ),
            RecordInfoLine(
              icon: Icons.phone_outlined,
              text: donor.contactNumber ?? '—',
            ),
          ],
          extraChips: [
            _buildClaimBadge(donor.isClaimed),
            _buildEligibilityBadge(donor.eligibility),
          ],
          detailFields: [
            RecordDetailField(
                label: 'Eligibility Status', value: donor.eligibility),
            RecordDetailField(
              label: 'Claim Status',
              value: donor.claimStatus,
              valueColor:
                  donor.isClaimed ? AppColors.success : AppColors.warning,
            ),
            RecordDetailField(
                label: 'Home Address', value: donor.homeAddress.fullAddress),
            RecordDetailField(
                label: 'Birthday', value: _formatDate(donor.birthday)),
            RecordDetailField(
                label: 'Occupation', value: donor.occupation ?? '—'),
            RecordDetailField(
                label: 'Responsible Staff',
                value: donor.staffName ?? 'MilkLink Staff'),
            RecordDetailField(
                label: 'Verified Profile',
                value: donor.verified ? 'Yes (Verified)' : 'No (Pending)'),
            RecordDetailField(
              label: 'Baby / Children',
              value: donor.children.isNotEmpty
                  ? donor.children.map((c) => c.name).join(', ')
                  : 'None listed',
            ),
          ],
          onKeyAction: donor.isDeleted || donor.isClaimed
              ? null
              : () => _generateDonorClaimToken(donor),
          keyActionTooltip: 'Generate Claim Token',
          onChecklistAction:
              donor.isDeleted ? null : () => _openDonorStatusDialog(donor),
          checklistActionTooltip: 'Edit donor status',
          onEdit: donor.isDeleted ? null : () => _openDonorDialog(donor: donor),
          onArchive: donor.isDeleted ? null : () => _archiveDonor(donor),
          onRestore: donor.isDeleted ? () => _restoreDonor(donor) : null,
          onDelete: () => _deleteDonor(donor),
        );
      },
    );
  }

  Widget _buildAdminRecipientsView(StaffProvider staffProvider) {
    final isArchived = _activeArchivedFilter == 1;
    final source = isArchived
        ? staffProvider.archivedPatients
        : staffProvider.activePatients;
    final list = _filterStaffRecords(source, _recordSearch);

    return RecordsListScaffold(
      title: 'Recipient Records',
      onBack: () => setState(() {
        _selectedModule = null;
        _recordSearchController.clear();
        _recordSearch = '';
        _activeArchivedFilter = 0;
      }),
      onRefresh: _handleRefresh,
      searchController: _recordSearchController,
      searchQuery: _recordSearch,
      onSearchChanged: (val) => setState(() => _recordSearch = val.trim()),
      searchHint: 'Search records...',
      activeCount: staffProvider.activePatients.length,
      archivedCount: staffProvider.archivedPatients.length,
      selectedFilter: _activeArchivedFilter,
      onFilterChanged: (filter) =>
          setState(() => _activeArchivedFilter = filter),
      isLoading: staffProvider.status == StaffLoadingStatus.loading &&
          staffProvider.activePatients.isEmpty &&
          staffProvider.archivedPatients.isEmpty,
      errorMessage: staffProvider.status == StaffLoadingStatus.error
          ? staffProvider.errorMessage
          : null,
      fabLabel: 'New Recipient',
      onFabPressed: () => _openPatientDialog(),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final patient = list[idx] as PatientModel;
        return RecordCard(
          title: patient.name,
          statusChipText: patient.patientType,
          isArchived: isArchived,
          infoLines: [
            RecordInfoLine(
              icon: Icons.calendar_today_outlined,
              text: patient.isDeleted
                  ? 'Archived on ${_formatDate(patient.deletedAt)}'
                  : 'Admitted on ${_formatDate(patient.admissionDate)}',
            ),
            RecordInfoLine(
              icon: Icons.person_outline,
              text: patient.motherName.isNotEmpty
                  ? "Mother: ${patient.motherName}"
                  : "Mother: —",
            ),
            RecordInfoLine(
              icon: Icons.phone_outlined,
              text: patient.phone.isNotEmpty ? patient.phone : '—',
            ),
          ],
          extraChips: [
            _buildClaimBadge(patient.isClaimed),
          ],
          detailFields: [
            RecordDetailField(
                label: 'Patient Type', value: patient.patientType),
            RecordDetailField(
                label: "Mother's Name", value: patient.motherName),
            RecordDetailField(label: 'Contact Phone', value: patient.phone),
            RecordDetailField(
              label: 'Claim Status',
              value: patient.claimStatus,
              valueColor:
                  patient.isClaimed ? AppColors.success : AppColors.warning,
            ),
            RecordDetailField(
                label: 'Home Address', value: patient.homeAddress.fullAddress),
            RecordDetailField(label: 'Age', value: '${patient.age} days old'),
            RecordDetailField(
                label: 'AOG (Weeks)', value: '${patient.aog} weeks'),
            RecordDetailField(
                label: 'Admission Date',
                value: _formatDate(patient.admissionDate)),
            RecordDetailField(
                label: 'Assigned Staff',
                value: patient.staffName ?? 'MilkLink Staff'),
          ],
          onKeyAction: patient.isDeleted || patient.isClaimed
              ? null
              : () => _generatePatientClaimToken(patient),
          keyActionTooltip: 'Generate Claim Token',
          onEdit:
              patient.isDeleted ? null : () => _openPatientDialog(patient: patient),
          onArchive:
              patient.isDeleted ? null : () => _archivePatient(patient),
          onRestore:
              patient.isDeleted ? () => _restorePatient(patient) : null,
          onDelete: () => _deletePatient(patient),
        );
      },
    );
  }

  void _archiveDonor(DonorModel donor) {
    _confirmRecordAction(
      title: 'Archive Donor Record',
      message: 'Move ${donor.displayName} to the archive?',
      actionLabel: 'Archive',
      actionColor: AppColors.warning,
      action: () => context.read<StaffProvider>().softDeleteDonor(donor.id),
    );
  }

  void _restoreDonor(DonorModel donor) {
    _confirmRecordAction(
      title: 'Restore Donor Record',
      message: 'Restore ${donor.displayName} to active records?',
      actionLabel: 'Restore',
      actionColor: AppColors.primaryNavy,
      action: () => context.read<StaffProvider>().restoreDonor(donor.id),
    );
  }

  void _deleteDonor(DonorModel donor) {
    _confirmRecordAction(
      title: 'Delete Donor Permanently',
      message:
          'Permanently delete ${donor.displayName}? This cannot be undone.',
      actionLabel: 'Delete Forever',
      actionColor: AppColors.error,
      action: () =>
          context.read<StaffProvider>().deleteDonorPermanently(donor.id),
    );
  }

  void _archivePatient(PatientModel patient) {
    _confirmRecordAction(
      title: 'Archive Recipient Record',
      message: 'Move ${patient.name} to the archive?',
      actionLabel: 'Archive',
      actionColor: AppColors.warning,
      action: () => context.read<StaffProvider>().softDeletePatient(patient.id),
    );
  }

  void _restorePatient(PatientModel patient) {
    _confirmRecordAction(
      title: 'Restore Recipient Record',
      message: 'Restore ${patient.name} to active records?',
      actionLabel: 'Restore',
      actionColor: AppColors.primaryNavy,
      action: () => context.read<StaffProvider>().restorePatient(patient.id),
    );
  }

  void _deletePatient(PatientModel patient) {
    _confirmRecordAction(
      title: 'Delete Recipient Permanently',
      message: 'Permanently delete ${patient.name}? This cannot be undone.',
      actionLabel: 'Delete Forever',
      actionColor: AppColors.error,
      action: () =>
          context.read<StaffProvider>().deletePatientPermanently(patient.id),
    );
  }

  String _formatDate(DateTime? date) {
    return date == null ? '—' : DateFormat('MMM dd, yyyy').format(date);
  }
}
