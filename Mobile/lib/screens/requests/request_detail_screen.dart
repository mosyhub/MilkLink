import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/milk_request_model.dart';
import 'request_form_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final MilkRequestModel request;
  final VoidCallback onMutated;

  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.onMutated,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late MilkRequestModel _request;
  bool _isLoading = false;

  // Stock panel
  double _totalPasteurizedStock = 0;
  List<dynamic> _availableBatches = [];

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await ApiClient.get(ApiConstants.requestById(_request.id));
      if (res['success'] == true && res['request'] != null) {
        if (mounted) {
          setState(() {
            _request = MilkRequestModel.fromJson(res['request']);
            if (res['stockPanel'] is Map) {
              _totalPasteurizedStock = (res['stockPanel']['totalAvailableVolume'] as num?)?.toDouble() ?? 0;
              _availableBatches = res['stockPanel']['batches'] ?? [];
            }
          });
        }
      }
    } catch (_) {}
  }

  // --- ACTIONS ---

  Future<void> _startReview() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.requestStartReview(_request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinical review started. Status is now Under Review.'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordReview() async {
    final notesCtrl = TextEditingController(text: _request.clinicalReview?.assessmentNotes ?? '');
    String decision = _request.clinicalReview?.decision ?? 'Eligible';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Clinical Assessment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Record clinical justification before approval:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: decision,
                decoration: const InputDecoration(labelText: 'Eligibility Decision *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Eligible', child: Text('Eligible')),
                  DropdownMenuItem(value: 'Not Eligible', child: Text('Not Eligible')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => decision = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical Assessment Notes *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () {
                if (notesCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter assessment notes.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save Assessment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.requestRecordReview(_request.id), data: {
        'assessmentNotes': notesCtrl.text.trim(),
        'decision': decision,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinical review recorded!'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    if (_request.clinicalReview?.decision != 'Eligible') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record clinical review as Eligible before approving.')),
      );
      return;
    }

    final approvedVolCtrl = TextEditingController(text: _request.volumeRequested.toStringAsFixed(0));
    final Map<String, int> selectedBottles = {}; // batchId -> bottles count

    // Auto-select FEFO batches to cover requested volume
    double needed = _request.volumeRequested;
    for (final b in _availableBatches) {
      if (needed <= 0) break;
      final bId = b['_id']?.toString() ?? '';
      final bType = (b['bottleType'] as num?)?.toInt() ?? 100;
      final avail = (b['availableBottles'] as num?)?.toInt() ?? 0;

      final bottlesNeeded = (needed / bType).ceil();
      final take = bottlesNeeded > avail ? avail : bottlesNeeded;
      if (take > 0) {
        selectedBottles[bId] = take;
        needed -= (take * bType);
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalSelected = 0;
          for (final b in _availableBatches) {
            final bId = b['_id']?.toString() ?? '';
            final count = selectedBottles[bId] ?? 0;
            final bType = (b['bottleType'] as num?)?.toInt() ?? 100;
            totalSelected += (count * bType);
          }

          final appVol = double.tryParse(approvedVolCtrl.text) ?? 0;
          final diff = totalSelected - appVol;

          return AlertDialog(
            title: const Text('Approve Milk Request'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: approvedVolCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Approved Volume (mL) *',
                        border: OutlineInputBorder(),
                        helperText: 'Can be lowered for partial approval.',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text('Allocate Bottles (FEFO Order):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_availableBatches.isEmpty)
                      const Text('No pasteurized milk available in inventory.', style: TextStyle(color: AppColors.error))
                    else
                      ..._availableBatches.map((b) {
                        final bId = b['_id']?.toString() ?? '';
                        final bNum = b['batchNumber'] ?? 'N/A';
                        final bType = (b['bottleType'] as num?)?.toInt() ?? 100;
                        final avail = (b['availableBottles'] as num?)?.toInt() ?? 0;
                        final count = selectedBottles[bId] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Batch #$bNum ($bType mL)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('$avail bottles available', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: count > 0
                                          ? () => setDialogState(() => selectedBottles[bId] = count - 1)
                                          : null,
                                    ),
                                    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: count < avail
                                          ? () => setDialogState(() => selectedBottles[bId] = count + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const Divider(height: 20),
                    Text('Total Allocated: ${totalSelected.toInt()} mL', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (diff != 0)
                      Text(
                        diff > 0 ? '(+${diff.toInt()} mL difference due to fixed bottle size)' : '(-${(-diff).toInt()} mL shortage)',
                        style: TextStyle(fontSize: 12, color: diff < 0 ? AppColors.error : AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () {
                  if (totalSelected <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please allocate at least one bottle.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Confirm Approval'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final allocated = <Map<String, dynamic>>[];
      for (final b in _availableBatches) {
        final bId = b['_id']?.toString() ?? '';
        final count = selectedBottles[bId] ?? 0;
        if (count > 0) {
          allocated.add({
            'invId': bId,
            'batch': b['batchNumber'] ?? 'N/A',
            'pool': b['poolNumber'] ?? '',
            'bottleType': b['bottleType'] ?? 100,
            'bottlesAllocated': count,
            'expiration': b['expiration'],
          });
        }
      }

      await ApiClient.put(ApiConstants.requestApprove(_request.id), data: {
        'approvedVolume': double.tryParse(approvedVolCtrl.text) ?? _request.volumeRequested,
        'allocatedBatches': allocated,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved and bottles reserved!'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Milk Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a reason for rejection (this will be shown to the requester):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Rejection Reason *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.requestReject(_request.id), data: {
        'reason': reasonCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected.'), backgroundColor: AppColors.error),
      );
      widget.onMutated();
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fulfill() async {
    final receiverCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fulfill & Hand Over Milk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record physical handover details:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: receiverCtrl,
              decoration: const InputDecoration(
                labelText: "Receiver's Full Name *",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () {
              if (receiverCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm Handover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.requestFulfill(_request.id), data: {
        'receiverName': receiverCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request marked as Fulfilled! Bottles deducted from stock.'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fulfillment failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Milk Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter reason for cancellation:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Cancellation Reason *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.requestCancel(_request.id), data: {
        'reason': reasonCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled and reserved bottles released.')),
      );
      widget.onMutated();
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Request'),
        content: Text('Archive request #${_request.requestNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.softDeleteRequest(_request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request archived'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.restoreRequest(_request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request restored to active'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Request'),
        content: Text('Permanently delete #${_request.requestNumber}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.delete(ApiConstants.requestById(_request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request permanently deleted'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_request.requestNumber),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RequestFormScreen(request: _request)),
                ).then((res) {
                  if (res == true) {
                    widget.onMutated();
                    _refresh();
                  }
                });
              }
              if (val == 'archive') _archive();
              if (val == 'restore') _restore();
              if (val == 'delete') _delete();
            },
            itemBuilder: (ctx) => [
              if (_request.status == 'Pending')
                const PopupMenuItem(value: 'edit', child: Text('Edit Request')),
              if (!_request.isDeleted && ['Fulfilled', 'Rejected', 'Cancelled'].contains(_request.status))
                const PopupMenuItem(value: 'archive', child: Text('Archive')),
              if (_request.isDeleted) ...[
                const PopupMenuItem(value: 'restore', child: Text('Restore')),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Permanently', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildDetailsSection(),
                  const SizedBox(height: 16),
                  _buildClinicalReviewCard(),
                  const SizedBox(height: 16),
                  _buildStockPanel(),
                  const SizedBox(height: 16),
                  _buildHistorySection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_request.requestNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _statusBadge(_request.status),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.child_care, color: AppColors.primaryNavy, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_request.recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${_request.relationToRecipient} • ${_request.formattedDate}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Requested', _request.formattedVolumeRequested),
                  _statItem('Duration', '${_request.feedingDurationDays} days'),
                  _statItem('Approved', _request.formattedApprovedVolume),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy)),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            _infoRow(Icons.medical_services_outlined, 'Medical Indication', _request.reasonForRequest),
            const SizedBox(height: 12),
            _infoRow(Icons.local_hospital_outlined, 'Hospital / Address', _request.hospitalOrAddress),
            if (_request.additionalRemarks?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.notes_outlined, 'Remarks / Physician', _request.additionalRemarks!),
            ],
            if (_request.requester != null) ...[
              const Divider(height: 24),
              const Text('Requester Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              _infoRow(Icons.person_outline, 'Requester Name', _request.requester!.name),
              if (_request.requester!.phone != null) ...[
                const SizedBox(height: 8),
                _infoRow(Icons.phone_outlined, 'Contact Number', _request.requester!.phone!),
              ],
            ],
            if (_request.rejectionReason != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Rejection Reason: ${_request.rejectionReason}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
            if (_request.cancellationReason != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Cancellation Reason: ${_request.cancellationReason}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalReviewCard() {
    final cr = _request.clinicalReview;
    final isDone = cr != null && cr.decision != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDone ? AppColors.success.withValues(alpha: 0.4) : Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rate_review_outlined, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text('Clinical Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cr.isEligible ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cr.decision!,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cr.isEligible ? AppColors.success : AppColors.error),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            if (!isDone)
              const Text(
                'Clinical justification and eligibility decision must be recorded before approval.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              )
            else ...[
              _infoRow(Icons.badge_outlined, 'Reviewed By', cr.reviewerName ?? 'Staff'),
              const SizedBox(height: 8),
              if (cr.reviewDate != null)
                _infoRow(Icons.calendar_today_outlined, 'Review Date', DateFormat('MMM dd, yyyy').format(cr.reviewDate!)),
              const SizedBox(height: 8),
              _infoRow(Icons.notes, 'Assessment Notes', cr.assessmentNotes ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockPanel() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text('Pasteurized Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Text(
                  '${NumberFormat('#,##0').format(_totalPasteurizedStock)} mL Total',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_request.allocatedBatches.isNotEmpty) ...[
              const Text('Allocated Batches for this Request:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ..._request.allocatedBatches.map((b) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  title: Text('Batch #${b.batch} (${b.bottleType} mL bottles)'),
                  subtitle: Text('${b.bottlesAllocated} bottle(s) • ${b.volDischarge} mL'),
                );
              }),
            ] else if (_availableBatches.isEmpty)
              const Text('No pasteurized batches in stock currently.', style: TextStyle(color: AppColors.error, fontSize: 13))
            else
              Text(
                '${_availableBatches.length} batch(es) available in Pasteurizer inventory (FEFO sorted).',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request History & Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            if (_request.history.isEmpty)
              const Text('No history entries recorded yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            else
              ..._request.history.map((h) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFFE8EEF5),
                        child: Icon(Icons.history, size: 14, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(h.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(h.formattedDate, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                            Text('By ${h.actorName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            if (h.notes?.isNotEmpty == true)
                              Text(h.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final st = _request.status;
    return Column(
      children: [
        if (st == 'Pending')
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy, minimumSize: const Size.fromHeight(48)),
            onPressed: _startReview,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Clinical Review'),
          ),
        if (st == 'Under Review') ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue, minimumSize: const Size.fromHeight(48)),
            onPressed: _recordReview,
            icon: const Icon(Icons.edit_note),
            label: const Text('Record Assessment Decision'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size.fromHeight(48)),
                  onPressed: _request.clinicalReview?.decision == 'Eligible' ? _approve : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size.fromHeight(48)),
                  onPressed: _reject,
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
        if (st == 'Approved')
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy, minimumSize: const Size.fromHeight(48)),
            onPressed: _fulfill,
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Fulfill & Hand Over Milk'),
          ),
        if (st == 'Pending' || st == 'Under Review' || st == 'Approved') ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, minimumSize: const Size.fromHeight(44)),
            onPressed: _cancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Request'),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pending': color = Colors.orange; break;
      case 'Under Review': color = AppColors.primaryBlue; break;
      case 'Approved': color = AppColors.success; break;
      case 'Fulfilled': color = AppColors.primaryNavy; break;
      case 'Rejected': color = AppColors.error; break;
      case 'Cancelled': color = Colors.grey; break;
      default: color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}