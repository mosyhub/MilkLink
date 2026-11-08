import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/schedule_model.dart';
import 'schedule_form_screen.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleModel initialSchedule;
  final List<ScheduleModel> allActiveSchedules;
  final VoidCallback? onMutated;

  const ScheduleDetailScreen({
    super.key,
    required this.initialSchedule,
    this.allActiveSchedules = const [],
    this.onMutated,
  });

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  late ScheduleModel _schedule;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _schedule = widget.initialSchedule;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(ApiConstants.scheduleById(_schedule.id));
      if (res is Map && res['schedule'] is Map) {
        if (mounted) {
          setState(() {
            _schedule = ScheduleModel.fromJson(Map<String, dynamic>.from(res['schedule']));
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
        builder: (_) => ScheduleFormScreen(
          initialKind: _schedule.kind,
          schedule: _schedule,
          allActiveSchedules: widget.allActiveSchedules,
        ),
      ),
    );

    if (updated == true) {
      widget.onMutated?.call();
      await _refresh();
      _showSnackbar('Schedule updated successfully.');
    }
  }

  Future<void> _archive() async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Schedule',
      content: 'Are you sure you want to archive this ${_schedule.kind.toLowerCase()} schedule?',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteSchedule(_schedule.id));
      widget.onMutated?.call();
      _showSnackbar('Schedule archived.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to archive schedule.', isError: true);
    }
  }

  Future<void> _restore() async {
    try {
      await ApiClient.put(ApiConstants.restoreSchedule(_schedule.id));
      widget.onMutated?.call();
      _showSnackbar('Schedule restored to active list.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to restore schedule.', isError: true);
    }
  }

  Future<void> _delete() async {
    final confirm = await _showConfirmDialog(
      title: 'Permanently Delete',
      content: 'Are you sure you want to permanently delete this schedule? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.scheduleById(_schedule.id));
      widget.onMutated?.call();
      _showSnackbar('Schedule deleted permanently.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to delete schedule.', isError: true);
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
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
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
      case 'Scheduled':
      case 'Approved':
        return AppColors.info;
      case 'Completed':
      case 'Picked Up':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      case 'Pending':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = _schedule.isPickup;
    final statusColor = _getStatusColor(_schedule.effectiveStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_schedule.kind} Schedule Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          PopupMenuButton<String>(
            tooltip: 'Schedule options',
            onSelected: (val) {
              if (val == 'archive') _archive();
              if (val == 'restore') _restore();
              if (val == 'delete') _delete();
            },
            itemBuilder: (ctx) => [
              if (!_schedule.isDeleted)
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 20, color: AppColors.warning),
                      SizedBox(width: 10),
                      Text('Archive Schedule'),
                    ],
                  ),
                ),
              if (_schedule.isDeleted)
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.unarchive_outlined, size: 20, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Restore Schedule'),
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
                                Chip(
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  avatar: Icon(
                                    isPickup ? Icons.local_shipping : Icons.event,
                                    size: 16,
                                    color: AppColors.primaryNavy,
                                  ),
                                  label: Text(
                                    '${_schedule.kind} Schedule',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
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
                                    _schedule.effectiveStatus,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _schedule.displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_schedule.isDeleted) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.warning),
                                    SizedBox(width: 6),
                                    Text('Archived Record', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time details
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
                            const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            _detailRow(
                              icon: Icons.calendar_today,
                              label: isPickup ? 'Date Range' : 'Date',
                              value: _schedule.displayDate,
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _detailRow(
                              icon: Icons.schedule,
                              label: 'Time Window',
                              value: _schedule.displayTimeRange,
                              subtext: isPickup ? 'Applies to each day within date range' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location / Address Card
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
                            Text(
                              isPickup ? 'Pickup Location & Contact' : 'Event Location & Details',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            _detailRow(
                              icon: Icons.place_outlined,
                              label: isPickup ? 'Pickup Address' : 'Event Location',
                              value: _schedule.displayAddress.isNotEmpty ? _schedule.displayAddress : 'Not specified',
                            ),
                            if (isPickup) ...[
                              const Divider(height: 16, color: AppColors.border),
                              _detailRow(
                                icon: Icons.phone_outlined,
                                label: 'Contact Number',
                                value: _schedule.contactNumber.isNotEmpty ? _schedule.contactNumber : 'None provided',
                              ),
                              const Divider(height: 16, color: AppColors.border),
                              _detailRow(
                                icon: Icons.water_drop_outlined,
                                label: 'Total Volume',
                                value: '${_schedule.totalVolume.toStringAsFixed(0)} ml',
                              ),
                            ],
                            if (!isPickup && _schedule.description.isNotEmpty) ...[
                              const Divider(height: 16, color: AppColors.border),
                              _detailRow(
                                icon: Icons.notes_outlined,
                                label: 'Description',
                                value: _schedule.description,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isPickup && _schedule.pickupStatus == 'Picked Up') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Inventory Link Active',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'This collected donation is recorded in Collections and placed in the Unpasteurized refrigerator.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    // Action Buttons at bottom
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: AppColors.primaryNavy,
                              side: const BorderSide(color: AppColors.primaryNavy),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Schedule'),
                            onPressed: _edit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!_schedule.isDeleted)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.archive, size: 18),
                              label: const Text('Archive'),
                              onPressed: _archive,
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.unarchive, size: 18),
                              label: const Text('Restore'),
                              onPressed: _restore,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete Schedule Permanently'),
                      onPressed: _delete,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtext,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryNavy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

