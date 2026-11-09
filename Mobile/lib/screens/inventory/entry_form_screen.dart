import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';

class EntryFormScreen extends StatefulWidget {
  final FridgeEntryModel entry;
  final String fridgeType;

  const EntryFormScreen({
    super.key,
    required this.entry,
    required this.fridgeType,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime? _expiration;
  late final TextEditingController _donorController;
  late final TextEditingController _volumeController;
  late final TextEditingController _reasonController;

  final FocusNode _volumeFocus = FocusNode();
  final FocusNode _reasonFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _expiration = widget.entry.expiration;
    _donorController = TextEditingController(text: widget.entry.displayDonorName);
    _volumeController = TextEditingController(
      text: widget.entry.volume > 0 ? widget.entry.volume.toString() : '',
    );
    _reasonController = TextEditingController(text: widget.entry.reasonForChange);
  }

  @override
  void dispose() {
    _donorController.dispose();
    _volumeController.dispose();
    _reasonController.dispose();
    _volumeFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _pickExpiration() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiration ?? DateTime.now().add(const Duration(days: 14)),
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
      setState(() => _expiration = picked);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final vol = int.tryParse(_volumeController.text.trim()) ?? widget.entry.volume;
    final isVolChanged = vol != widget.entry.volume;

    if (isVolChanged && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for modifying the milk volume.'),
          backgroundColor: AppColors.error,
        ),
      );
      _reasonFocus.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'donorName': _donorController.text.trim(),
        'volume': vol,
        if (_expiration != null) 'expiration': DateFormat('yyyy-MM-dd').format(_expiration!),
        'reasonForChange': _reasonController.text.trim(),
      };

      await ApiClient.put(ApiConstants.inventoryById(widget.entry.id), data: payload);

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
          const SnackBar(content: Text('Failed to update entry.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Edit Fridge Entry', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text('Milk Entry Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _donorController,
                          decoration: const InputDecoration(
                            labelText: 'Donor Name *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Donor name is required' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _volumeController,
                          focusNode: _volumeFocus,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Volume (ml) *',
                            prefixIcon: Icon(Icons.water_drop_outlined),
                            border: OutlineInputBorder(),
                            helperText: 'Integer value in ml',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Volume is required';
                            final n = int.tryParse(v.trim());
                            if (n == null || n <= 0) return 'Enter a positive integer volume';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        InkWell(
                          onTap: _pickExpiration,
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
                                    _expiration != null
                                        ? 'Expiration Date: ${DateFormat('MMMM dd, yyyy').format(_expiration!)}'
                                        : 'Select Expiration Date',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _reasonController,
                          focusNode: _reasonFocus,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Adjustment',
                            hintText: 'e.g. Volume re-verification, spillage adjustment',
                            prefixIcon: Icon(Icons.notes),
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
                            Text('Saving Entry...'),
                          ],
                        )
                      : const Text('Update Fridge Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

