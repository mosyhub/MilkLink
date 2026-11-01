import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/patient_model.dart';
import '../../../models/request_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class RequestFormDialog extends StatefulWidget {
  final RequestModel? initialRequest;
  final List<PatientModel> availablePatients;
  final Function(Map<String, dynamic> data) onSave;

  const RequestFormDialog({
    Key? key,
    this.initialRequest,
    required this.availablePatients,
    required this.onSave,
  }) : super(key: key);

  @override
  State<RequestFormDialog> createState() => _RequestFormDialogState();
}

class _RequestFormDialogState extends State<RequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String _patientType = 'Inpatient';
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _status = 'Pending';
  DateTime? _requestDate;
  bool _isSubmitting = false;

  final List<String> _statusOptions = ['Pending', 'Reserved', 'Done', 'Canceled'];
  final List<String> _patientTypes = ['Inpatient', 'Outpatient'];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRequest;
    _selectedPatientId = r?.patientId.isNotEmpty == true ? r!.patientId : (widget.availablePatients.isNotEmpty ? widget.availablePatients.first.id : null);
    _patientType = r?.patientType ?? 'Inpatient';
    _diagnosisController.text = r?.diagnosis ?? '';
    _reasonController.text = r?.reason ?? '';
    _doctorController.text = r?.doctor ?? '';
    _locationController.text = r?.department ?? r?.hospital ?? 'NICU';
    _volumeController.text = r != null && r.volume > 0 ? r.volume.toStringAsFixed(0) : '200';
    _daysController.text = r != null && r.days > 0 ? r.days.toString() : '3';
    _commentController.text = r?.comment ?? '';
    _status = r?.status ?? 'Pending';
    _requestDate = r?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _reasonController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _volumeController.dispose();
    _daysController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final vol = double.tryParse(_volumeController.text.trim()) ?? 100.0;
    final dys = int.tryParse(_daysController.text.trim()) ?? 1;

    final payload = {
      'patient': _selectedPatientId,
      'patientType': _patientType,
      'diagnosis': _diagnosisController.text.trim(),
      'reason': _reasonController.text.trim(),
      'doctor': _doctorController.text.trim(),
      'location': _locationController.text.trim(),
      if (_patientType == 'Inpatient')
        'department': _locationController.text.trim()
      else
        'hospital': _locationController.text.trim(),
      'volumeRequested': {
        'volume': vol,
        'days': dys,
      },
      'status': _status,
      'date': _requestDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      if (_commentController.text.trim().isNotEmpty) 'comment': _commentController.text.trim(),
    };

    await widget.onSave(payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRequest != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_task,
                    color: AppColors.primaryNavy,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Milk Request' : 'Add Milk Request',
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
                        // Select Patient
                        const Text('Patient *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        if (widget.availablePatients.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedPatientId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: widget.availablePatients.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.name} (${p.patientType})', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPatientId = val;
                                final p = widget.availablePatients.firstWhere((element) => element.id == val);
                                _patientType = p.patientType;
                              });
                            },
                          )
                        else
                          CustomTextField(
                            label: 'Patient ID',
                            hint: 'Enter Patient Mongo ID',
                            controller: TextEditingController(text: _selectedPatientId ?? ''),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        const SizedBox(height: 14),

                        // Patient Type
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

                        // Diagnosis
                        CustomTextField(
                          label: 'Diagnosis *',
                          hint: 'e.g. Preterm Low Birth Weight',
                          controller: _diagnosisController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Reason
                        CustomTextField(
                          label: 'Reason for Request *',
                          hint: 'e.g. Maternal illness / Delayed lactation',
                          controller: _reasonController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Doctor
                        CustomTextField(
                          label: 'Prescribing Doctor *',
                          hint: 'e.g. Dr. A. Santos, MD',
                          controller: _doctorController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Location (Department or Hospital)
                        CustomTextField(
                          label: _patientType == 'Inpatient' ? 'Department / Ward *' : 'Hospital / Clinic *',
                          hint: _patientType == 'Inpatient' ? 'e.g. NICU / Ward 3' : 'e.g. Pasig-Pateros District Hospital',
                          controller: _locationController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Volume & Days
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Volume (mL) *',
                                hint: 'e.g. 200',
                                controller: _volumeController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Duration (Days) *',
                                hint: 'e.g. 3',
                                controller: _daysController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Status
                        const Text('Request Status *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _status = val!),
                        ),
                        const SizedBox(height: 14),

                        // Comment
                        CustomTextField(
                          label: 'Notes / Comments (Optional)',
                          hint: 'Additional patient / delivery notes',
                          controller: _commentController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Submit Request',
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

