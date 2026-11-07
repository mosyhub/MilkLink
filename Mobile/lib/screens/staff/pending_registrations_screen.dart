import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/donor_model.dart';
import '../../providers/staff_provider.dart';
import 'package:provider/provider.dart';

class PendingRegistrationsScreen extends StatefulWidget {
  const PendingRegistrationsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRegistrationsScreen> createState() => _PendingRegistrationsScreenState();
}

class _PendingRegistrationsScreenState extends State<PendingRegistrationsScreen> {
  bool _isLoading = true;
  List<dynamic> _registrations = [];
  Map<String, dynamic> _summary = {};
  String _searchQuery = '';
  int _tabFilter = 0; // 0: All, 1: Unlinked (Pending Verification), 2: Linked

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  Future<void> _fetchRegistrations() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(ApiConstants.staffPendingRegistrations);
      if (response['success'] == true) {
        setState(() {
          _registrations = response['registrations'] ?? [];
          _summary = response['summary'] ?? {};
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load pending online registrations'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _linkToExistingDonor(Map<String, dynamic> reg) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final donors = staffProvider.activeDonors;

    DonorModel? selectedDonor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Link to Existing Donor Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${reg['fullName']} (@${reg['username']})\nPhone: ${reg['phone']}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text('Select Existing Donor Profile:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (donors.isEmpty)
                  const Text('No active donor records found. Create one first.', style: TextStyle(color: AppColors.error, fontSize: 12))
                else
                  DropdownButtonFormField<DonorModel>(
                    isExpanded: true,
                    value: selectedDonor,
                    hint: const Text('Choose donor profile', style: TextStyle(fontSize: 13)),
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    items: donors.map((d) {
                      return DropdownMenuItem<DonorModel>(
                        value: d,
                        child: Text(
                          '${d.donorId ?? "ID"} — ${d.displayName} (${d.eligibility})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedDonor = val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: selectedDonor == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Confirm Link'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedDonor == null) return;

    try {
      final response = await ApiClient.post(
        ApiConstants.staffLinkUserToDonor(reg['id']),
        data: {'donorId': selectedDonor!.id},
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Donor linked successfully!'), backgroundColor: AppColors.success),
        );
        _fetchRegistrations();
        staffProvider.fetchDonors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to link donor profile'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _createNewDonorProfile(Map<String, dynamic> reg) async {
    final streetCtrl = TextEditingController();
    final brgyCtrl = TextEditingController();
    DateTime? birthDate;
    String donorType = 'Community';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Donor Record for User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${reg['fullName']}\nPhone: ${reg['phone']}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                const Text('Date of Birth *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(1998, 1, 1),
                      firstDate: DateTime(1960),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => birthDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(birthDate != null ? '${birthDate!.year}-${birthDate!.month}-${birthDate!.day}' : 'Select Birthday', style: const TextStyle(fontSize: 13)),
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryNavy),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Street Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(controller: streetCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'House / Street')),
                const SizedBox(height: 12),
                const Text('Barangay in Pasig *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(controller: brgyCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Barangay name')),
                const SizedBox(height: 12),
                const Text('Donor Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: donorType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Community', child: Text('Community')),
                    DropdownMenuItem(value: 'Private', child: Text('Private')),
                    DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => donorType = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPink),
              onPressed: () {
                if (birthDate == null || streetCtrl.text.trim().isEmpty || brgyCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiClient.post(
        ApiConstants.staffCreateDonorForUser(reg['id']),
        data: {
          'birthday': birthDate!.toIso8601String(),
          'street': streetCtrl.text.trim(),
          'brgy': brgyCtrl.text.trim(),
          'city': 'Pasig City',
          'donorType': donorType,
          'eligibility': 'Pending Review',
        },
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Donor profile created successfully!'), backgroundColor: AppColors.success),
        );
        _fetchRegistrations();
        Provider.of<StaffProvider>(context, listen: false).fetchDonors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create donor profile'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var displayList = _registrations;

    // Filter by tab: 1 = Unlinked, 2 = Linked
    if (_tabFilter == 1) {
      displayList = displayList.where((r) => r['isLinkedToDonor'] == false).toList();
    } else if (_tabFilter == 2) {
      displayList = displayList.where((r) => r['isLinkedToDonor'] == true).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayList = displayList.where((r) {
        final name = (r['fullName'] ?? '').toString().toLowerCase();
        final username = (r['username'] ?? '').toString().toLowerCase();
        final phone = (r['phone'] ?? '').toString().toLowerCase();
        final email = (r['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || username.contains(q) || phone.contains(q) || email.contains(q);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Online Registrations'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRegistrations),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTabButton('All (${_summary['total'] ?? 0})', 0),
                const SizedBox(width: 8),
                _buildTabButton('Pending (${_summary['pendingCount'] ?? 0})', 1),
                const SizedBox(width: 8),
                _buildTabButton('Linked (${_summary['verifiedCount'] ?? 0})', 2),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, username, contact number...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? const Center(
                        child: Text('No pending online registrations found.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: displayList.length,
                        itemBuilder: (ctx, idx) => _buildUserRegistrationCard(displayList[idx]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabFilter = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPink : AppColors.softBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.primaryNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserRegistrationCard(Map<String, dynamic> reg) {
    final isLinked = reg['isLinkedToDonor'] == true;
    final apt = reg['screeningAppointment'];
    final dateStr = reg['createdAt'] != null ? reg['createdAt'].toString().split('T')[0] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLinked ? AppColors.success.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reg['fullName'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLinked ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLinked ? 'Verified / Linked' : 'Temporary Account',
                  style: TextStyle(
                    color: isLinked ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '@${reg['username']} • Phone: ${reg['phone']} • Registered: $dateStr',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (reg['email'] != null && reg['email'] != 'N/A')
            Text('Email: ${reg['email']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          // Appointment status banner
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  apt != null ? Icons.event_available : Icons.event_busy,
                  size: 16,
                  color: apt != null ? AppColors.primaryNavy : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    apt != null
                        ? 'Screening Apt: ${apt['appointmentId'] ?? ''} (${apt['status']}) on ${apt['date'] != null ? apt['date'].toString().split('T')[0] : ''}'
                        : 'No screening appointment booked yet',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Linked Donor details if linked
          if (isLinked && reg['linkedDonor'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Linked Donor: ${reg['linkedDonor']['donorId'] ?? ''} (${reg['linkedDonor']['eligibility']})',
              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isLinked) ...[
                OutlinedButton.icon(
                  onPressed: () => _linkToExistingDonor(reg),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Link to Donor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _createNewDonorProfile(reg),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Create Donor Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPink,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ] else ...[
                const Text('Account verified & linked', style: TextStyle(fontSize: 12, color: AppColors.success, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
