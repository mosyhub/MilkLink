import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';

class FridgeFormScreen extends StatefulWidget {
  final FridgeModel? fridge;

  const FridgeFormScreen({super.key, this.fridge});

  @override
  State<FridgeFormScreen> createState() => _FridgeFormScreenState();
}

class _FridgeFormScreenState extends State<FridgeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late String _fridgeType;
  final FocusNode _nameFocus = FocusNode();

  bool _isSubmitting = false;

  bool get _isEdit => widget.fridge != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fridge?.name ?? '');
    _fridgeType = widget.fridge?.fridgeType ?? 'Unpasteurized';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'fridgeType': _fridgeType,
      };

      if (_isEdit) {
        await ApiClient.put(ApiConstants.fridgeById(widget.fridge!.id), data: data);
      } else {
        await ApiClient.post(ApiConstants.fridges, data: data);
      }

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
          const SnackBar(content: Text('Failed to save refrigerator.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Refrigerator' : 'New Refrigerator';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text('Refrigerator Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          decoration: const InputDecoration(
                            labelText: 'Refrigerator Name *',
                            hintText: 'e.g. Fridge #1 (Unpasteurized Deep Freeze)',
                            prefixIcon: Icon(Icons.kitchen),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Refrigerator name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _fridgeType,
                          decoration: const InputDecoration(
                            labelText: 'Refrigerator Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Unpasteurized', child: Text('Unpasteurized (Raw Milk Storage)')),
                            DropdownMenuItem(value: 'Pasteurized', child: Text('Pasteurized (Batches for Dispensing)')),
                          ],
                          onChanged: (val) => setState(() => _fridgeType = val ?? 'Unpasteurized'),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: AppColors.primaryNavy),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fridgeType == 'Unpasteurized'
                                      ? 'Unpasteurized fridges receive collected raw milk from pickups and supply milk for pasteurization pooling.'
                                      : 'Pasteurized fridges hold processed batches ready for infant request fulfillment (FEFO).',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy),
                                ),
                              ),
                            ],
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
                            Text('Saving Refrigerator...'),
                          ],
                        )
                      : Text(_isEdit ? 'Update Refrigerator' : 'Create Refrigerator', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

