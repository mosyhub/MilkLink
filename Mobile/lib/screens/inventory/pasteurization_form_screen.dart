import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';

class PasteurizationFormScreen extends StatefulWidget {
  final FridgeModel sourceFridge;
  final List<FridgeEntryModel> selectedEntries;
  final List<FridgeModel> pasteurizedFridges;

  const PasteurizationFormScreen({
    super.key,
    required this.sourceFridge,
    required this.selectedEntries,
    required this.pasteurizedFridges,
  });

  @override
  State<PasteurizationFormScreen> createState() => _PasteurizationFormScreenState();
}

class _PasteurizationFormScreenState extends State<PasteurizationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _pasteurizationDate;
  late String _targetFridgeId;

  late final TextEditingController _batchController;
  late final TextEditingController _poolController;
  late final TextEditingController _bottleTypeController;
  late final TextEditingController _bottlesCountController;

  final FocusNode _batchFocus = FocusNode();
  final FocusNode _poolFocus = FocusNode();
  final FocusNode _bottleTypeFocus = FocusNode();
  final FocusNode _bottlesCountFocus = FocusNode();

  bool _isSubmitting = false;

int get _pooledVolume => widget.selectedEntries
    .fold<double>(0, (sum, e) => sum + e.volume)
    .round();

  List<String> get _pooledDonorNames {
    final set = <String>{};
    for (final e in widget.selectedEntries) {
      if (e.donorName.isNotEmpty) set.add(e.donorName);
      for (final d in e.donorNames) {
        if (d.isNotEmpty) set.add(d);
      }
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _pasteurizationDate = DateTime.now();

    _targetFridgeId = widget.pasteurizedFridges.isNotEmpty
        ? widget.pasteurizedFridges.first.id
        : '';

    // Auto-generate candidate batch and pool numbers from timestamp
    final timestampSeed = (DateTime.now().millisecondsSinceEpoch % 100000);
    _batchController = TextEditingController(text: '${1000 + (timestampSeed % 9000)}');
    _poolController = TextEditingController(text: '${100 + (timestampSeed % 900)}');

    _bottleTypeController = TextEditingController(text: '100');
    // Calculate estimated bottle count based on 100ml bottles
    final estBottles = (_pooledVolume / 100).floor();
    _bottlesCountController = TextEditingController(text: estBottles > 0 ? '$estBottles' : '1');
  }

  @override
  void dispose() {
    _batchController.dispose();
    _poolController.dispose();
    _bottleTypeController.dispose();
    _bottlesCountController.dispose();

    _batchFocus.dispose();
    _poolFocus.dispose();
    _bottleTypeFocus.dispose();
    _bottlesCountFocus.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pasteurizationDate,
      firstDate: DateTime(2020),
      lastDate: now, // cannot be in future
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
      setState(() => _pasteurizationDate = picked);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_targetFridgeId.isEmpty) {
      _showSnackbar('Please select a target Pasteurized refrigerator', isError: true);
      return;
    }

    final bType = int.tryParse(_bottleTypeController.text.trim()) ?? 0;
    final bCount = int.tryParse(_bottlesCountController.text.trim()) ?? 0;
    final totalPlannedVolume = bType * bCount;

    if (totalPlannedVolume > _pooledVolume) {
      _showSnackbar('Total bottle volume ($totalPlannedVolume ml) exceeds pooled volume ($_pooledVolume ml)', isError: true);
      return;
    }

    // Warn on large mismatch (> 15% difference) and let user confirm
    final diff = _pooledVolume - totalPlannedVolume;
    if (diff > (_pooledVolume * 0.15)) {
      final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Volume Mismatch Warning'),
              content: Text(
                'The pooled volume is $_pooledVolume ml, but only $totalPlannedVolume ml ($bCount bottles x $bType ml) will be bottled.\n\n$diff ml of pooled milk will not be bottled. Do you want to proceed?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Adjust Numbers')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirm Pasteurization'),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'unpasteurizedFridgeId': widget.sourceFridge.id,
        'pasteurizedFridgeId': _targetFridgeId,
        'selectedEntryIds': widget.selectedEntries.map((e) => e.id).toList(),
        'pasteurizationDate': DateFormat('yyyy-MM-dd').format(_pasteurizationDate),
        'batchNumber': int.parse(_batchController.text.trim()),
        'poolNumber': int.parse(_poolController.text.trim()),
        'bottleType': bType,
        'availableBottles': bCount,
      };

      await ApiClient.post(ApiConstants.pasteurize, data: payload);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackbar(e.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackbar('Failed to pasteurize batch. Check connection and retry.', isError: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pasteurize Milk Batch', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Pool Summary Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hub_outlined, color: AppColors.primaryNavy),
                            const SizedBox(width: 8),
                            Text(
                              'Pooled Milk Summary (${widget.selectedEntries.length} entries)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pooled Volume:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '$_pooledVolume ml',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryNavy),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Contributing Donors in Pool:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _pooledDonorNames.map((d) {
                            return Chip(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.background,
                              avatar: const Icon(Icons.person, size: 14, color: AppColors.primaryNavy),
                              label: Text(d, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Destination Refrigerator Selector
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
                        const Text('Destination Pasteurized Refrigerator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        if (widget.pasteurizedFridges.isEmpty)
                          const Text('No Pasteurized refrigerators found. Please create one in Refrigerators tab.', style: TextStyle(color: AppColors.error))
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _targetFridgeId,
                            decoration: const InputDecoration(
                              labelText: 'Pasteurized Fridge *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.kitchen),
                            ),
                            items: widget.pasteurizedFridges.map((f) {
                              return DropdownMenuItem(value: f.id, child: Text('${f.name} (${f.totalVolume} ml)'));
                            }).toList(),
                            onChanged: (val) => setState(() => _targetFridgeId = val ?? ''),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pasteurization Batch Specifications Card
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
                        const Text('Batch & Bottle Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 14),

                        // Pasteurization Date (cannot be in future)
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event, color: AppColors.primaryNavy),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Pasteurization Date: ${DateFormat('MMMM dd, yyyy').format(_pasteurizationDate)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _batchController,
                                focusNode: _batchFocus,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Batch Number *',
                                  hintText: 'e.g. 101',
                                  prefixIcon: Icon(Icons.tag),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _poolController,
                                focusNode: _poolFocus,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Pool Number *',
                                  hintText: 'e.g. 202',
                                  prefixIcon: Icon(Icons.layers_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _bottleTypeController,
                                focusNode: _bottleTypeFocus,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Bottle Type (ml) *',
                                  hintText: 'e.g. 100',
                                  prefixIcon: Icon(Icons.local_drink),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _bottlesCountController,
                                focusNode: _bottlesCountFocus,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'No. of Bottles *',
                                  hintText: 'e.g. 5',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Builder(builder: (ctx) {
                          final bType = int.tryParse(_bottleTypeController.text.trim()) ?? 0;
                          final bCount = int.tryParse(_bottlesCountController.text.trim()) ?? 0;
                          final planned = bType * bCount;
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: planned <= _pooledVolume ? AppColors.infoBg : AppColors.errorBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  planned <= _pooledVolume ? Icons.check_circle_outline : Icons.error_outline,
                                  size: 16,
                                  color: planned <= _pooledVolume ? AppColors.info : AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bottled Volume: $planned ml / $_pooledVolume ml pooled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: planned <= _pooledVolume ? AppColors.info : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
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
                            Text('Processing Pasteurization...'),
                          ],
                        )
                      : const Text('Confirm Pasteurization Batch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

