import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/milk_request_model.dart';

class RequestFormScreen extends StatefulWidget {
  final MilkRequestModel? request; // null if creating, non-null if editing

  const RequestFormScreen({super.key, this.request});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _recipientNameCtrl;
  late final TextEditingController _volumeCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _hospitalCtrl;
  late final TextEditingController _remarksCtrl;
  late String _relation;

  bool _isSaving = false;
  bool _hasChanges = false;

  bool get _isEditing => widget.request != null;

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    _recipientNameCtrl = TextEditingController(text: r?.recipientName ?? '');
    _volumeCtrl = TextEditingController(
      text: r != null ? r.volumeRequested.toStringAsFixed(0) : '500',
    );
    _durationCtrl = TextEditingController(
      text: r != null ? r.feedingDurationDays.toString() : '7',
    );
    _reasonCtrl = TextEditingController(text: r?.reasonForRequest ?? '');
    _hospitalCtrl = TextEditingController(
      text: r?.hospitalOrAddress ?? 'Pasig-Pateros District Hospital',
    );
    _remarksCtrl = TextEditingController(text: r?.additionalRemarks ?? '');
    _relation = r?.relationToRecipient ?? 'Mother / Guardian';

    _recipientNameCtrl.addListener(_onFieldChanged);
    _volumeCtrl.addListener(_onFieldChanged);
    _durationCtrl.addListener(_onFieldChanged);
    _reasonCtrl.addListener(_onFieldChanged);
    _hospitalCtrl.addListener(_onFieldChanged);
    _remarksCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _recipientNameCtrl.dispose();
    _volumeCtrl.dispose();
    _durationCtrl.dispose();
    _reasonCtrl.dispose();
    _hospitalCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'recipientName': _recipientNameCtrl.text.trim(),
        'relationToRecipient': _relation,
        'volumeRequested': double.tryParse(_volumeCtrl.text.trim()) ?? 500,
        'feedingDurationDays': int.tryParse(_durationCtrl.text.trim()) ?? 7,
        'reasonForRequest': _reasonCtrl.text.trim(),
        'hospitalOrHomeAddress': _hospitalCtrl.text.trim(),
        'additionalRemarks': _remarksCtrl.text.trim(),
      };

      if (_isEditing) {
        await ApiClient.put(ApiConstants.requestById(widget.request!.id), data: payload);
      } else {
        await ApiClient.post(ApiConstants.requests,data: payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Request updated' : 'Request created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Milk Request' : 'New Milk Request (Walk-in/Phone)'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _recipientNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name (Infant) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.child_care),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _relation,
                decoration: const InputDecoration(
                  labelText: 'Relationship to Infant *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                items: const [
                  DropdownMenuItem(value: 'Mother / Guardian', child: Text('Mother / Guardian')),
                  DropdownMenuItem(value: 'Father', child: Text('Father')),
                  DropdownMenuItem(value: 'Healthcare Provider', child: Text('Healthcare Provider')),
                  DropdownMenuItem(value: 'Relative / Foster', child: Text('Relative / Foster')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _relation = v;
                      _hasChanges = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _volumeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Volume (mL) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Invalid volume';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (Days)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Medical Indication / Reason for Request *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hospitalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hospital / Admitting Unit / Home Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarksCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Physician / Additional Remarks',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Create Milk Request',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

