import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/screening_appointment_model.dart';

class StaffScreeningAppointmentsScreen extends StatefulWidget {
  const StaffScreeningAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<StaffScreeningAppointmentsScreen> createState() => _StaffScreeningAppointmentsScreenState();
}

class _StaffScreeningAppointmentsScreenState extends State<StaffScreeningAppointmentsScreen> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  Map<String, dynamic> _summary = {};
  String? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      String url = ApiConstants.staffScreeningAppointments;
      if (_statusFilter != null) {
        url += '?status=$_statusFilter';
      }
      final response = await ApiClient.get(url);
      if (response['success'] == true) {
        setState(() {
          _appointments = response['appointments'] ?? [];
          _summary = response['summary'] ?? {};
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load screening appointments'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String appointmentId, String status) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark Appointment as $status?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to mark this appointment as "$status"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Notes / Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status.contains('Reject') ? AppColors.error : AppColors.accentPink,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiClient.put(
        ApiConstants.staffAppointmentStatus(appointmentId),
        data: {
          'status': status,
          'statusReason': reasonController.text.trim(),
        },
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment updated to $status'), backgroundColor: AppColors.success),
        );
        _fetchAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openCompleteScreeningDialog(Map<String, dynamic> apt) async {
    final notesController = TextEditingController();
    String selectedEligibility = 'Eligible';
    bool updateDonor = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Complete Screening Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment: ${apt['appointmentId'] ?? ''}\nPurpose: ${apt['purpose'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                const Text('Medical Eligibility Decision:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedEligibility,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'Eligible', child: Text('Eligible (Approved for donation)')),
                    DropdownMenuItem(value: 'For Laboratory Verification', child: Text('For Laboratory Verification')),
                    DropdownMenuItem(value: 'For Medical Assessment', child: Text('For Medical Assessment')),
                    DropdownMenuItem(value: 'Temporarily Deferred', child: Text('Temporarily Deferred')),
                    DropdownMenuItem(value: 'Not Eligible', child: Text('Not Eligible')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedEligibility = val);
                  },
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Update Donor Profile Status', style: TextStyle(fontSize: 13)),
                  value: updateDonor,
                  onChanged: (v) => setDialogState(() => updateDonor = v ?? true),
                ),
                const SizedBox(height: 10),
                const Text('Clinical Screening Notes / Observations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'CBC and rapid tests reviewed, vitals normal...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Decision'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final response = await ApiClient.post(
        ApiConstants.staffCompleteScreening(apt['_id']),
        data: {
          'attendanceRecorded': true,
          'screeningCompleted': true,
          'staffReviewNotes': notesController.text.trim(),
          'eligibilityStatus': selectedEligibility,
          'updateDonorEligibility': updateDonor,
        },
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screening visit completed and donor status updated!'), backgroundColor: AppColors.success),
        );
        _fetchAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete screening'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var displayList = _appointments;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayList = displayList.where((a) {
        final aptId = (a['appointmentId'] ?? '').toString().toLowerCase();
        final purpose = (a['purpose'] ?? '').toString().toLowerCase();
        String uName = '';
        if (a['user'] is Map && a['user']['name'] is Map) {
          uName = '${a['user']['name']['first'] ?? ''} ${a['user']['name']['last'] ?? ''}'.toLowerCase();
        }
        return aptId.contains(q) || purpose.contains(q) || uName.contains(q);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Screening Clinic'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAppointments),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('Pending', 'Pending Confirmation', count: _summary['pendingCount']),
                _buildFilterChip('Confirmed', 'Confirmed', count: _summary['confirmedCount']),
                _buildFilterChip('Attended', 'Attended', count: _summary['attendedCount']),
                _buildFilterChip('Completed', 'Completed', count: _summary['completedCount']),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search donor name, APT ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          const SizedBox(height: 8),

          // Appointment List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? const Center(child: Text('No screening appointments found.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayList.length,
                        itemBuilder: (ctx, idx) => _buildAppointmentCard(displayList[idx]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? statusVal, {dynamic count}) {
    final isSelected = _statusFilter == statusVal;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(count != null ? '$label ($count)' : label),
        selectedColor: AppColors.accentPink.withOpacity(0.2),
        checkmarkColor: AppColors.accentPink,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.accentPink : AppColors.textPrimary,
          fontSize: 12,
        ),
        onSelected: (val) {
          setState(() => _statusFilter = val ? statusVal : null);
          _fetchAppointments();
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    String donorName = 'User';
    String donorPhone = '';
    if (apt['user'] is Map) {
      final u = apt['user'];
      if (u['name'] is Map) donorName = '${u['name']['first'] ?? ''} ${u['name']['last'] ?? ''}'.trim();
      donorPhone = u['phone'] ?? '';
    }

    final status = apt['status']?.toString() ?? 'Pending Confirmation';
    Color badgeColor = Colors.orange;
    if (status == 'Confirmed') badgeColor = Colors.blue;
    if (status == 'Attended' || status == 'Completed') badgeColor = Colors.green;
    if (status.contains('Reject') || status.contains('Cancel')) badgeColor = Colors.red;

    final dateStr = apt['appointmentDate'] != null ? apt['appointmentDate'].toString().split('T')[0] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                apt['appointmentId'] ?? 'APT-PENDING',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(donorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (donorPhone.isNotEmpty)
            Text('Contact: $donorPhone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('$dateStr  •  ${apt['timeSlot'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          if (apt['donorNotes'] != null && apt['donorNotes'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Donor Notes: ${apt['donorNotes']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'Pending Confirmation') ...[
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _updateStatus(apt['_id'], 'Rejected by Staff'),
                  child: const Text('Reject Slot'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  onPressed: () => _updateStatus(apt['_id'], 'Confirmed'),
                  child: const Text('Confirm Slot'),
                ),
              ] else if (status == 'Confirmed') ...[
                OutlinedButton(
                  onPressed: () => _updateStatus(apt['_id'], 'Attended'),
                  child: const Text('Record Attendance'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Complete Screening'),
                  onPressed: () => _openCompleteScreeningDialog(apt),
                ),
              ] else if (status == 'Attended') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  icon: const Icon(Icons.verified, size: 16),
                  label: const Text('Complete Screening & Update Donor'),
                  onPressed: () => _openCompleteScreeningDialog(apt),
                ),
              ] else ...[
                Text(
                  'Visit record finalized',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
