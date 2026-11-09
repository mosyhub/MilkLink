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
import '../../widgets/stacked_data_card.dart';
import '../../widgets/admin/admin_module_card.dart';
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


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminModule? _selectedModule;
  int _bottomIndex = 0;
  final TextEditingController _recordSearchController = TextEditingController();
  String _recordSearch = '';

  @override
  void dispose() {
    _recordSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refresh();
      final staffProvider = context.read<StaffProvider>();
      staffProvider.fetchDonors();
      staffProvider.fetchDonors(isArchived: true);
      staffProvider.fetchPatients();
      staffProvider.fetchPatients(isArchived: true);
    });
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
          title: const Text('Edit Donor Status'),
          content: Column(
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
          title: const Text('Edit Recipient Status'),
          content: DropdownButtonFormField<String>(
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
        title: Text(title),
        content: Text(message),
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
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryNavy,
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.softBlue,
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.volunteer_activism,
                        color: AppColors.primaryBlue,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MilkLink Portal',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications')),
                ),
                icon: const Icon(Icons.notifications_none),
              ),
              IconButton(
                tooltip: 'Log out',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: _buildDrawer(),
          body: _selectedModule == null
              ? _buildHome(provider, staffProvider)
              : _buildModule(provider, staffProvider, _selectedModule!),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _bottomIndex,
            onDestinationSelected: (index) {
              setState(() {
                _bottomIndex = index;
                _selectedModule = switch (index) {
                  1 => AdminModule.metrics,
                  2 => AdminModule.requests,
                  _ => null,
                };
              });
            },
            indicatorColor: AppColors.softBlue,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                label: 'Requests',
              ),
            ],
          ),
          floatingActionButton: _buildAdminFab(),
        );
      },
    );
  }

  Widget? _buildAdminFab() {
    if (_selectedModule == AdminModule.donors) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        onPressed: _openDonorDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Donor'),
      );
    }
    if (_selectedModule == AdminModule.recipients) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        onPressed: _openPatientDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Recipient'),
      );
    }
    return null;
  }

  Widget _buildHome(AdminProvider provider, StaffProvider staffProvider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text(
            'Good day, Admin',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Pasig City Human Milk Bank administration'),
          const SizedBox(height: 20),
          if (provider.status == AdminLoadStatus.error)
            Card(
              color: AppColors.errorBg,
              child: ListTile(
                leading:
                    const Icon(Icons.error_outline, color: AppColors.error),
                title: const Text('Dashboard data unavailable'),
                subtitle: Text(provider.errorMessage ?? 'Try again later.'),
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: .98,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: AdminModule.values.map((module) {
              final records = module == AdminModule.donors
                  ? staffProvider.activeDonors
                  : module == AdminModule.recipients
                      ? staffProvider.activePatients
                      : provider.data.recordsFor(module);
              return AdminModuleCard(
                module: module,
                count: records.isEmpty ? null : records.length,
                onTap: () => _selectModule(module),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModule(
    AdminProvider provider,
    StaffProvider staffProvider,
    AdminModule module,
  ) {
    if (module == AdminModule.schedules) {
      return const SchedulesScreen();
    }
    if (module == AdminModule.inventory) {
      return const InventoryScreen();
    }
    if (module == AdminModule.accounts) {
      return const AccountManagementScreen();
    }
    if (module == AdminModule.content) {
      return const ContentManagementScreen();
    }
    if (module == AdminModule.requests) {
      return const MilkRequestsScreen();
    }
    if (module == AdminModule.metrics) {
      return const MetricsDashboardScreen();
    }
    if (module == AdminModule.donors || module == AdminModule.recipients) {
      return _buildStaffRecordsModule(staffProvider, module);
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

  Widget _buildStaffRecordsModule(
      StaffProvider staffProvider, AdminModule module) {
    final isDonors = module == AdminModule.donors;
    final active =
        isDonors ? staffProvider.activeDonors : staffProvider.activePatients;
    final archived = isDonors
        ? staffProvider.archivedDonors
        : staffProvider.archivedPatients;
    final query = _recordSearch.toLowerCase();
    final activeRecords = _filterStaffRecords(active, query);
    final archivedRecords = _filterStaffRecords(archived, query);

    return Column(
      children: [
        _buildModuleHeader(module),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _recordSearchController,
            onChanged: (value) => setState(() => _recordSearch = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search ${isDonors ? 'donors' : 'recipients'}...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _recordSearch.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _recordSearchController.clear();
                        setState(() => _recordSearch = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const Material(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppColors.primaryNavy,
                    indicatorColor: AppColors.primaryBlue,
                    tabs: [
                      Tab(text: 'Active Records'),
                      Tab(text: 'Archived Records'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildStaffRecordList(
                        activeRecords,
                        isDonors,
                        isArchived: false,
                      ),
                      _buildStaffRecordList(
                        archivedRecords,
                        isDonors,
                        isArchived: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleHeader(AdminModule module) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedModule = null),
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          ),
          Text(
            module.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterStaffRecords(List<dynamic> records, String query) {
    if (query.isEmpty) return records;
    return records.where((record) {
      final values = record is DonorModel
          ? [
              record.displayName,
              record.donorType,
              record.contactNumber ?? '',
              record.homeAddress.brgy,
            ]
          : [
              (record as PatientModel).name,
              record.motherName,
              record.patientType,
              record.phone,
            ];
      return values.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Widget _buildStaffRecordList(
    List<dynamic> records,
    bool isDonors, {
    required bool isArchived,
  }) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          'No ${isDonors ? 'donor' : 'recipient'} records found.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        if (isDonors) {
          final donor = record as DonorModel;
          return StackedDataCard(
            title: donor.displayName,
            subtitle: 'Registered ${_formatDate(donor.createdAt)}',
            isArchived: isArchived,
            statusBadge: _statusBadge(donor.eligibility),
            fields: [
              DataFieldItem(label: 'Donor Type', value: donor.donorType),
              DataFieldItem(
                label: 'Contact Number',
                value: donor.contactNumber ?? '—',
              ),
              DataFieldItem(
                label: 'Barangay',
                value: donor.homeAddress.brgy,
              ),
              DataFieldItem(
                label: 'Children',
                value: donor.children.isEmpty
                    ? 'None listed'
                    : donor.children.map((child) => child.name).join(', '),
              ),
            ],
            onEdit: isArchived ? null : () => _openDonorDialog(donor: donor),
            onUpdateStatus:
                isArchived ? null : () => _openDonorStatusDialog(donor),
            statusActionLabel: 'Edit donor status',
            onArchive: isArchived ? null : () => _archiveDonor(donor),
            onRestore: isArchived ? () => _restoreDonor(donor) : null,
            onDelete: () => _deleteDonor(donor),
          );
        }

        final patient = record as PatientModel;
        return StackedDataCard(
          title: patient.name,
          subtitle: 'Admitted ${_formatDate(patient.admissionDate)}',
          isArchived: isArchived,
          statusBadge: _statusBadge(patient.patientType),
          fields: [
            DataFieldItem(label: 'Patient Type', value: patient.patientType),
            DataFieldItem(label: "Mother's Name", value: patient.motherName),
            DataFieldItem(label: 'Phone', value: patient.phone),
            DataFieldItem(label: 'Gestational Age', value: patient.aog ?? '—'),
            DataFieldItem(label: 'Barangay', value: patient.homeAddress.brgy),
          ],
          onEdit:
              isArchived ? null : () => _openPatientDialog(patient: patient),
          onUpdateStatus:
              isArchived ? null : () => _openPatientStatusDialog(patient),
          statusActionLabel: 'Edit recipient status',
          onArchive: isArchived ? null : () => _archivePatient(patient),
          onRestore: isArchived ? () => _restorePatient(patient) : null,
          onDelete: () => _deletePatient(patient),
        );
      },
    );
  }

  Widget _statusBadge(String value) {
    return Chip(
      label: Text(value),
      labelStyle: const TextStyle(fontSize: 11, color: AppColors.primaryNavy),
      backgroundColor: AppColors.softBlue,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
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

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primaryNavy),
              child: Text(
                'MilkLink Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final module in AdminModule.values)
              ListTile(
                leading: Icon(module.icon, color: AppColors.primaryBlue),
                title: Text(module.label),
                onTap: () {
                  Navigator.pop(context);
                  _selectModule(module);
                },
              ),
          ],
        ),
      ),
    );
  }
}
