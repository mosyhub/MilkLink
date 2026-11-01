import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../models/patient_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class PatientFormDialog extends StatefulWidget {
  final PatientModel? initialPatient;
  final List<PatientModel>? availablePatients;
  final Function(Map<String, dynamic> data) onSave;

  const PatientFormDialog({
    Key? key,
    this.initialPatient,
    this.availablePatients,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Search & Record linkage
  final TextEditingController _searchController = TextEditingController();
  PatientModel? _selectedPatient;
  List<PatientModel> _searchResults = [];
  Timer? _debounceTimer;

  // Form Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _aogController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _brgyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String _patientType = 'Inpatient';
  DateTime? _admissionDate;
  bool _isSubmitting = false;

  final List<String> _patientTypes = ['Inpatient', 'Outpatient'];

  @override
  void initState() {
    super.initState();
    final p = widget.initialPatient;
    if (p != null) {
      _populateFromPatient(p);
    } else {
      _cityController.text = 'Pasig City';
      _admissionDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _motherNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _aogController.dispose();
    _streetController.dispose();
    _brgyController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _populateFromPatient(PatientModel p) {
    _selectedPatient = p;
    _nameController.text = p.name;
    _motherNameController.text = p.motherName;
    _phoneController.text = p.phone;
    _ageController.text = p.age ?? '';
    _aogController.text = p.aog ?? '';
    _streetController.text = p.homeAddress.street;
    _brgyController.text = p.homeAddress.brgy;
    _cityController.text =
        p.homeAddress.city.isNotEmpty ? p.homeAddress.city : 'Pasig City';
    if (_patientTypes.contains(p.patientType)) {
      _patientType = p.patientType;
    }
    _admissionDate = p.admissionDate ?? DateTime.now();
  }

  void _searchRecords(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      // 1. Instant match from available local patients
      final local = (widget.availablePatients ?? []).where((p) {
        return p.name.toLowerCase().contains(clean) ||
            p.motherName.toLowerCase().contains(clean) ||
            p.phone.toLowerCase().contains(clean);
      }).toList();

      if (mounted) {
        setState(() => _searchResults = local);
      }

      // 2. Query backend API to capture records from all pages
      try {
        final response = await ApiClient.get(
          '${ApiConstants.patients}?search=${Uri.encodeComponent(clean)}',
        );
        if (response is Map && response['patients'] is List) {
          final remote = (response['patients'] as List)
              .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted) {
            final Map<String, PatientModel> map = {
              for (final item in local) item.id: item,
              for (final item in remote) item.id: item,
            };
            setState(() {
              _searchResults = map.values.toList();
            });
          }
        }
      } catch (_) {}
    });
  }

  void _selectExistingPatient(PatientModel p) {
    setState(() {
      _populateFromPatient(p);
      _searchResults = [];
      _searchController.text = '${p.name} (Mother: ${p.motherName})';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Existing record loaded for "${p.name}". Fields auto-populated.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearSelectedPatient() {
    setState(() {
      _selectedPatient = null;
      _searchController.clear();
      _searchResults = [];
      _nameController.clear();
      _motherNameController.clear();
      _phoneController.clear();
      _ageController.clear();
      _aogController.clear();
      _streetController.clear();
      _brgyController.clear();
      _cityController.text = 'Pasig City';
      _patientType = 'Inpatient';
      _admissionDate = DateTime.now();
    });
  }

  Future<void> _pickAdmissionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _admissionDate = picked);
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      if (_selectedPatient != null) '_id': _selectedPatient!.id,
      'name': _nameController.text.trim(),
      'motherName': _motherNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'patientType': _patientType,
      'age': _ageController.text.trim(),
      'aog': _aogController.text.trim(),
      if (_admissionDate != null) 'admissionDate': _admissionDate!.toIso8601String(),
      'home_address': {
        'street': _streetController.text.trim(),
        'brgy': _brgyController.text.trim(),
        'city': _cityController.text.trim(),
      },
    };

    await widget.onSave(payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPatient != null || _selectedPatient != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
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
                    isEditing ? Icons.edit_note : Icons.child_care,
                    color: AppColors.primaryNavy,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Recipient Record' : 'Recipient Intake / Registration',
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

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Search & Autocomplete Header ───────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.softBlue.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.35)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.search, size: 18, color: AppColors.primaryNavy),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Search Existing Recipient Database',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Type baby name, mother name, or phone number to find existing records and auto-fill.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Baby Leo or Maria Santos or 0912...',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  prefixIcon: const Icon(Icons.person_search, size: 20, color: AppColors.primaryNavy),
                                  suffixIcon: (_searchController.text.isNotEmpty || _selectedPatient != null)
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: _clearSelectedPatient,
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: _searchRecords,
                              ),

                              // Existing Record Loaded Badge
                              if (_selectedPatient != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success, width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Loaded: ${_selectedPatient!.name} • Mother: ${_selectedPatient!.motherName}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: _clearSelectedPatient,
                                        child: const Text(
                                          'Unlink',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryNavy,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Search Results List
                              if (_searchResults.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final item = _searchResults[i];
                                      return ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppColors.softBlue,
                                          child: Icon(Icons.child_care, size: 16, color: AppColors.primaryNavy),
                                        ),
                                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        subtitle: Text(
                                          'Mother: ${item.motherName} • ${item.phone} • ${item.patientType}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        trailing: const Text(
                                          'Select',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primaryNavy,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onTap: () => _selectExistingPatient(item),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Patient (Infant) Name ─────────────────────────
                        CustomTextField(
                          label: 'Patient (Infant) Name *',
                          hint: 'e.g. Baby Boy Santos',
                          controller: _nameController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            if (_selectedPatient == null && val.trim().length >= 2) {
                              _searchRecords(val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Mother's Name ─────────────────────────────────
                        CustomTextField(
                          label: "Mother's Name *",
                          hint: 'e.g. Maria Santos',
                          controller: _motherNameController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          onChanged: (val) {
                            if (_selectedPatient == null && val.trim().length >= 2) {
                              _searchRecords(val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Patient Type ──────────────────────────────────
                        const Text('Patient Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _patientType,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _patientTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setState(() => _patientType = val!),
                        ),
                        const SizedBox(height: 14),

                        // ── Phone ─────────────────────────────────────────
                        CustomTextField(
                          label: 'Contact Number *',
                          hint: 'e.g. 09123456789',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // ── Age & AOG Row ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Age',
                                hint: 'e.g. 5 days / 2 mos',
                                controller: _ageController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'AOG',
                                hint: 'e.g. 36 weeks',
                                controller: _aogController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Admission Date ────────────────────────────────
                        const Text('Admission Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickAdmissionDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryNavy),
                                const SizedBox(width: 10),
                                Text(
                                  _admissionDate != null
                                      ? DateFormat('MMMM dd, yyyy').format(_admissionDate!)
                                      : 'Select Admission Date',
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
                          hint: 'e.g. 456 Pasig Blvd',
                          controller: _streetController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Barangay *',
                          hint: 'e.g. Kapasigan',
                          controller: _brgyController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'City *',
                          hint: 'e.g. Pasig City',
                          controller: _cityController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Recipient Record',
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
