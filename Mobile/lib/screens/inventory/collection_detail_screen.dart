import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';
import 'collection_form_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final CollectionModel collection;
  final VoidCallback? onMutated;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    this.onMutated,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late CollectionModel _collection;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(ApiConstants.collectionById(_collection.id));
      if (res is Map && res['collection'] is Map) {
        if (mounted) {
          setState(() {
            _collection = CollectionModel.fromJson(Map<String, dynamic>.from(res['collection']));
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionFormScreen(collection: _collection),
      ),
    );

    if (updated == true) {
      widget.onMutated?.call();
      await _refresh();
      _showSnackbar('Collection record updated.');
    }
  }

  Future<void> _archive() async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Collection',
      content: 'Archive this collection record? (Note: Milk already stored in the refrigerator will remain intact).',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteCollection(_collection.id));
      widget.onMutated?.call();
      _showSnackbar('Collection record archived.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to archive collection.', isError: true);
    }
  }

  Future<void> _restore() async {
    try {
      await ApiClient.put(ApiConstants.restoreCollection(_collection.id));
      widget.onMutated?.call();
      _showSnackbar('Collection record restored.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to restore collection.', isError: true);
    }
  }

  Future<void> _delete() async {
    final confirm = await _showConfirmDialog(
      title: 'Permanently Delete',
      content: 'Permanently delete this collection record? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.collectionById(_collection.id));
      widget.onMutated?.call();
      _showSnackbar('Collection record deleted permanently.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to delete collection.', isError: true);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Stored':
        return AppColors.info;
      case 'Collected':
        return AppColors.success;
      case 'Dispensed':
        return AppColors.primaryNavy;
      case 'Pending':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_collection.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collection Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit Collection',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          PopupMenuButton<String>(
            tooltip: 'Collection actions',
            onSelected: (val) {
              if (val == 'archive') _archive();
              if (val == 'restore') _restore();
              if (val == 'delete') _delete();
            },
            itemBuilder: (ctx) => [
              if (!_collection.isDeleted)
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 20, color: AppColors.warning),
                      SizedBox(width: 10),
                      Text('Archive Collection'),
                    ],
                  ),
                ),
              if (_collection.isDeleted)
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.unarchive_outlined, size: 20, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Restore Collection'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Delete Permanently', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Chip(
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  avatar: Icon(Icons.water_drop, size: 16, color: AppColors.primaryNavy),
                                  label: Text(
                                    'Milk Collection',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                                  ),
                                  backgroundColor: AppColors.softBlue,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _collection.status,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _collection.displayName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Collection Date: ${_collection.formattedCollectionDate}',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pickup Details card (read-only here, edited in Schedules)
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pickup Details (Schedules Link)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Text('Read-Only Here', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _detailRow(icon: Icons.person_outline, label: 'Name of Donor', value: _collection.displayName),
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Pickup Date Range',
                              value: _collection.dateRange.isNotEmpty ? _collection.dateRange : 'Not recorded',
                            ),
                            if (_collection.timeWindow.isNotEmpty) ...[
                              const Divider(height: 16, color: AppColors.border),
                              _detailRow(icon: Icons.schedule, label: 'Time Window', value: _collection.timeWindow),
                            ],
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.place_outlined,
                              label: 'Pickup Address',
                              value: _collection.pickupAddress.isNotEmpty ? _collection.pickupAddress : 'Not specified',
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.phone_outlined,
                              label: 'Contact Number',
                              value: _collection.contactNumber.isNotEmpty ? _collection.contactNumber : 'None provided',
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.local_shipping_outlined,
                              label: 'Pickup Status',
                              value: _collection.pickupStatus,
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.water_drop,
                              label: 'Total Volume',
                              value: '${_collection.effectiveVolume.toStringAsFixed(0)} ml',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Collection Info & Volume Correction card
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
                            const Text('Collection & Inventory Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            _detailRow(
                              icon: Icons.inventory_2_outlined,
                              label: 'Stored Location',
                              value: 'Unpasteurized Refrigerator (Pending Pasteurization)',
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.event_available,
                              label: 'Collection Date',
                              value: _collection.formattedCollectionDate,
                            ),
                            if (_collection.reasonForCorrection.isNotEmpty) ...[
                              const Divider(height: 16, color: AppColors.border),
                              _detailRow(
                                icon: Icons.notes,
                                label: 'Reason for Volume Correction',
                                value: _collection.reasonForCorrection,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Edit button
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Collection Date & Status'),
                      onPressed: _edit,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryNavy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

