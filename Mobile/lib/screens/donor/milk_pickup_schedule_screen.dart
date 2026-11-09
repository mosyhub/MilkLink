import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class MilkPickupScheduleScreen extends StatefulWidget {
  const MilkPickupScheduleScreen({Key? key}) : super(key: key);

  @override
  State<MilkPickupScheduleScreen> createState() => _MilkPickupScheduleScreenState();
}

class _MilkPickupScheduleScreenState extends State<MilkPickupScheduleScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bagsController = TextEditingController(text: '1');
  final _volumeController = TextEditingController(text: '300');
  final _notesController = TextEditingController();

  String _selectedBarangay = 'San Nicolas';
  String _selectedTimeSlot = 'Morning (8:00 AM - 11:30 AM)';
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  final List<String> _pasigBarangays = [
    'Bagong Ilog',
    'Bagong Katipunan',
    'Bambang',
    'Buting',
    'Caniogan',
    'De La Paz',
    'Kalawaan',
    'Kapasigan',
    'Kapitolyo',
    'Malinao',
    'Manggahan',
    'Maybunga',
    'Oranbo',
    'Palatiw',
    'Pinagbuhatan',
    'Pineda',
    'Rosario',
    'Sagad',
    'San Antonio',
    'San Joaquin',
    'San Jose',
    'San Miguel',
    'San Nicolas',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Rosa',
    'Santolan',
    'Santo Tomas',
    'Sumilang',
    'Ugong',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _bagsController.dispose();
    _volumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPickup() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select preferred collection date.')),
      );
      return;
    }
    if (_addressController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide street address and contact phone.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiClient.post(
        '${ApiConstants.baseUrl}/pickup/request',
        data: {
          'barangay': _selectedBarangay,
          'pickupAddress': _addressController.text.trim(),
          'preferredDate': _selectedDate!.toIso8601String(),
          'preferredTimeSlot': _selectedTimeSlot,
          'estimatedBags': int.tryParse(_bagsController.text.trim()) ?? 1,
          'estimatedVolumeMl': double.tryParse(_volumeController.text.trim()) ?? 300,
          'contactNumber': _phoneController.text.trim(),
          'donorNotes': _notesController.text.trim(),
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        final pickupId = response['pickupId'] ?? 'Scheduled';
        final outpost = response['assignedOutpost']?['outpostName'] ?? 'Pasig Station';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.local_shipping, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Pickup Confirmed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup Reference: $pickupId', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Assigned Outpost: $outpost'),
                const SizedBox(height: 8),
                const Text(
                  'Our milk collection driver and temperature-controlled cooler will arrive on your selected slot. Please keep milk frozen until collection.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppTopBar(title: 'Schedule Milk Pickup'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Home Pickup Collection Service',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coordinated across 5 Pasig City Human Milk Bank collection outposts.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBarangay,
              decoration: const InputDecoration(labelText: 'Barangay in Pasig *'),
              items: _pasigBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBarangay = val);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Exact Street Address / Landmark *',
              controller: _addressController,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Contact Number *',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _selectedDate == null
                    ? 'Select Collection Date *'
                    : 'Date: ${DateFormat('EEE, MMMM dd, yyyy').format(_selectedDate!)}',
              ),
              trailing: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: _selectedTimeSlot,
              decoration: const InputDecoration(labelText: 'Preferred Time Slot'),
              items: const [
                DropdownMenuItem(
                  value: 'Morning (8:00 AM - 11:30 AM)',
                  child: Text('Morning (8:00 AM - 11:30 AM)'),
                ),
                DropdownMenuItem(
                  value: 'Afternoon (1:00 PM - 4:30 PM)',
                  child: Text('Afternoon (1:00 PM - 4:30 PM)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedTimeSlot = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Est. Bags (qty)',
                    controller: _bagsController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Est. Volume (mL)',
                    controller: _volumeController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Notes for Collection Driver (Optional)',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit Pickup Request',
              isLoading: _isSubmitting,
              onPressed: _submitPickup,
            ),
          ],
        ),
      ),
    );
  }
}
