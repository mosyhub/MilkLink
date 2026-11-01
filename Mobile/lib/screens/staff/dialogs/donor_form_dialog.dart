import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/donor_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class DonorFormDialog extends StatefulWidget {
  final DonorModel? initialDonor;
  final Function(Map<String, dynamic> data) onSave;

  const DonorFormDialog({
    Key? key,
    this.initialDonor,
    required this.onSave,
  }) : super(key: key);

  @override
  State<DonorFormDialog> createState() => _DonorFormDialogState();
}

class _DonorFormDialogState extends State<DonorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String _donorType = 'Community';
  String _eligibility = 'Pending Review';

  // Controllers initialized directly to avoid LateInitializationError during hot reloads
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _childAgeWeeksController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _brgyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  DateTime? _birthday;
  bool _isSubmitting = false;

  final List<String> _donorTypes = [
    'Community',
    'Private',
    'Employee',
    'Network Office/Agency',
  ];

  final List<String> _eligibilityOptions = [
    'Pending Review',
    'For Laboratory Verification',
    'For Medical Assessment',
    'Eligible',
    'Temporarily Deferred',
    'Not Eligible',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialDonor;
    if (d != null) {
      if (_donorTypes.contains(d.donorType)) {
        _donorType = d.donorType;
      }
      if (_eligibilityOptions.contains(d.eligibility)) {
        _eligibility = d.eligibility;
      }
      _firstNameController.text = d.nameFirst ?? '';
      _middleNameController.text = d.nameMiddle ?? '';
      _lastNameController.text = d.nameLast ?? '';

      if (d.children.isNotEmpty) {
        final firstChild = d.children.first;
        _childNameController.text = firstChild.name;
        _childAgeWeeksController.text =
            firstChild.ageValue != null ? firstChild.ageValue.toString() : '';
      }

      _contactController.text = d.contactNumber ?? '';
      _occupationController.text = d.occupation ?? '';
      _streetController.text = d.homeAddress.street;
      _brgyController.text = d.homeAddress.brgy;
      _cityController.text =
          d.homeAddress.city.isNotEmpty ? d.homeAddress.city : 'Pasig City';
      _birthday = d.birthday ?? DateTime(1995, 1, 1);
    } else {
      _cityController.text = 'Pasig City';
      _birthday = DateTime(1995, 1, 1);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _childNameController.dispose();
    _childAgeWeeksController.dispose();
    _contactController.dispose();
    _occupationController.dispose();
    _streetController.dispose();
    _brgyController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select donor birthday')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final childName = _childNameController.text.trim();
    final childAgeWeeks = int.tryParse(_childAgeWeeksController.text.trim());

    // Send name as the `name` object — matches the backend Donor schema exactly
    final payload = {
      'name': {
        'first': _firstNameController.text.trim(),
        'middle': _middleNameController.text.trim(),
        'last': _lastNameController.text.trim(),
      },
      'donorType': _donorType,
      'eligibility': _eligibility,
      'contact_number': _contactController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'birthday': _birthday!.toIso8601String(),
      'home_address': {
        'street': _streetController.text.trim(),
        'brgy': _brgyController.text.trim(),
        'city': _cityController.text.trim(),
      },
      if (childName.isNotEmpty || childAgeWeeks != null)
        'children': [
          {
            'name': childName.isNotEmpty ? childName : 'Baby',
            'age': {
              'value': childAgeWeeks ?? 0,
              'unit': 'weeks',
            },
          }
        ],
    };

    await widget.onSave(payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialDonor != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.person_add_alt_1,
                    color: AppColors.primaryNavy,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Donor Record' : 'Create Donor Record',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // ── Scrollable Form ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Donor Name ────────────────────────────────────
                        const Text(
                          'Donor Name',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Stored in the system as the official donor identity.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          label: 'First Name *',
                          hint: 'e.g. Maria',
                          controller: _firstNameController,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Middle Name',
                          hint: 'e.g. Cruz (optional)',
                          controller: _middleNameController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Last Name *',
                          hint: 'e.g. Santos',
                          controller: _lastNameController,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Infant / Child Information ───────────────────
                        const Text(
                          'Infant / Child Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Baby name and age in weeks.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          label: 'Baby Name (Optional)',
                          hint: 'e.g. Baby Leo',
                          controller: _childNameController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Baby Age (Weeks)',
                          hint: 'e.g. 4',
                          controller: _childAgeWeeksController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Donor Type ────────────────────────────────────
                        const Text('Donor Type *',
                            style:
                                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _donorType,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _donorTypes
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) => setState(() => _donorType = val!),
                        ),
                        const SizedBox(height: 14),

                        // ── Contact Number ────────────────────────────────
                        CustomTextField(
                          label: 'Contact Number *',
                          hint: 'e.g. 09123456789',
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // ── Occupation ────────────────────────────────────
                        CustomTextField(
                          label: 'Occupation',
                          hint: 'e.g. Teacher / Homemaker',
                          controller: _occupationController,
                        ),
                        const SizedBox(height: 14),

                        // ── Birthday ──────────────────────────────────────
                        const Text('Birthday *',
                            style:
                                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickBirthday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: AppColors.primaryNavy),
                                const SizedBox(width: 10),
                                Text(
                                  _birthday != null
                                      ? DateFormat('MMMM dd, yyyy')
                                          .format(_birthday!)
                                      : 'Select Birthday',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Address ───────────────────────────────────────
                        CustomTextField(
                          label: 'Street Address *',
                          hint: 'e.g. 123 Caruncho Ave',
                          controller: _streetController,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Barangay *',
                          hint: 'e.g. San Nicolas',
                          controller: _brgyController,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'City *',
                          hint: 'e.g. Pasig City',
                          controller: _cityController,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // ── Eligibility ───────────────────────────────────
                        const Text('Eligibility Status *',
                            style:
                                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _eligibility,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _eligibilityOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _eligibility = val!),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Donor',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
