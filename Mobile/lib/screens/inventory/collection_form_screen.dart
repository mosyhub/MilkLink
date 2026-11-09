import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';

class CollectionFormScreen extends StatefulWidget {
  final CollectionModel collection;

  const CollectionFormScreen({
    super.key,
    required this.collection,
  });

  @override
  State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _collectionDate;
  late String _status;
  late final TextEditingController _volumeController;
  late final TextEditingController _reasonController;

  final FocusNode _volumeFocus = FocusNode();
  final FocusNode _reasonFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _collectionDate = widget.collection.collectionDate;
    _status = widget.collection.status;
    _volumeController = TextEditingController(
      text: widget.collection.effectiveVolume > 0
          ? widget.collection.effectiveVolume.toStringAsFixed(0)
          : '',
    );
    _reasonController = TextEditingController(
      text: widget.collection.reasonForCorrection,
    );
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _reasonController.dispose();
    _volumeFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryNavy,
              primary: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _collectionDate = picked);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final vol = double.tryParse(_volumeController.text.trim()) ?? widget.collection.effectiveVolume;
    final isVolumeChanged = (vol - widget.collection.effectiveVolume).abs() > 0.01;

    if (isVolumeChanged && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for correcting the collected volume.'),
          backgroundColor: AppColors.error,
        ),
      );
      _reasonFocus.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiClient.put(
        ApiConstants.collectionById(widget.collection.id),
        data: {
          'collectionDate': DateFormat('yyyy-MM-dd').format(_collectionDate),
          'status': _status,
          'volume': vol,
          'reasonForCorrection': _reasonController.text.trim(),
        },
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update collection.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Edit Collection Record', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                minimumSize: const Size(80, 40),
              ),
              onPressed: _isSubmitting ? null : _save,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSubmitting ? 'Saving' : 'Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Donor Info header
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Linked Pickup Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text(widget.collection.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                        if (widget.collection.dateRange.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Date Range: ${widget.collection.dateRange}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Collection Date Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collection Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.primaryNavy),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMMM dd, yyyy').format(_collectionDate),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status & Volume Correction Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status & Volume Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Collection Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Collected', child: Text('Collected')),
                            DropdownMenuItem(value: 'Stored', child: Text('Stored')),
                            DropdownMenuItem(value: 'Dispensed', child: Text('Dispensed')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          ],
                          onChanged: (val) => setState(() => _status = val ?? 'Collected'),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _volumeController,
                          focusNode: _volumeFocus,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Correct Volume (ml) *',
                            prefixIcon: Icon(Icons.water_drop_outlined),
                            border: OutlineInputBorder(),
                            helperText: 'Volume in ml. Changing volume requires a reason.',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Volume is required';
                            final num = double.tryParse(v.trim());
                            if (num == null || num <= 0) return 'Enter a positive volume';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _reasonController,
                          focusNode: _reasonFocus,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Correction',
                            hintText: 'e.g. Milk re-measurement at depot, leakage correction',
                            prefixIcon: Icon(Icons.edit_note),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting ? null : _save,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Saving Changes...'),
                          ],
                        )
                      : const Text('Update Collection Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

