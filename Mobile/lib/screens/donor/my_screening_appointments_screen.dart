import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/screening_appointment_model.dart';
import 'book_screening_appointment_screen.dart';

class MyScreeningAppointmentsScreen extends StatefulWidget {
  const MyScreeningAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<MyScreeningAppointmentsScreen> createState() => _MyScreeningAppointmentsScreenState();
}

class _MyScreeningAppointmentsScreenState extends State<MyScreeningAppointmentsScreen> {
  bool _isLoading = true;
  List<ScreeningAppointmentModel> _appointments = [];
  ScreeningAppointmentModel? _activeAppointment;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(ApiConstants.myScreeningAppointments);
      if (response['success'] == true) {
        final List list = response['appointments'] ?? [];
        final parsed = list.map((a) => ScreeningAppointmentModel.fromJson(a)).toList();
        setState(() {
          _appointments = parsed;
          if (response['activeAppointment'] != null) {
            _activeAppointment = ScreeningAppointmentModel.fromJson(response['activeAppointment']);
          } else {
            _activeAppointment = null;
          }
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load appointments';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load your appointment records.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(ScreeningAppointmentModel apt) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your appointment on ${apt.appointmentDate.toIso8601String().split('T')[0]} (${apt.timeSlot})?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Appointment')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiClient.put(
        ApiConstants.cancelScreeningAppointment(apt.id),
        data: {'reason': reasonController.text.trim()},
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully.'), backgroundColor: AppColors.success),
        );
        _fetchAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel appointment.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      backgroundColor: AppColors.surface,
      floatingActionButton: _activeAppointment == null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Book Screening'),
              onPressed: () async {
                final booked = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookScreeningAppointmentScreen()),
                );
                if (booked == true) _fetchAppointments();
              },
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _fetchAppointments, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAppointments,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active Appointment Card
                      if (_activeAppointment != null) ...[
                        const Text(
                          'Upcoming Screening Appointment',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        _buildActiveAppointmentCard(_activeAppointment!),
                        const SizedBox(height: 24),
                      ],

                      // Appointment History
                      const Text(
                        'Appointment History',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      if (_appointments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'No hospital screening appointments found.\nTap "Book Screening" below to schedule your visit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                            ),
                          ),
                        )
                      else
                        ..._appointments.map((apt) => _buildHistoryItem(apt)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActiveAppointmentCard(ScreeningAppointmentModel apt) {
    Color statusColor = AppColors.warning;
    if (apt.isConfirmed) statusColor = AppColors.success;
    if (apt.isCancelled) statusColor = AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  apt.appointmentId,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  apt.status,
                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            apt.purpose,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${apt.appointmentDate.year}-${apt.appointmentDate.month.toString().padLeft(2, '0')}-${apt.appointmentDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(apt.timeSlot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.room, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${apt.hospitalRoom}, ${apt.hospitalName}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (apt.donorNotes != null && apt.donorNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Notes: ${apt.donorNotes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _cancelAppointment(apt),
                child: const Text('Cancel Appointment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ScreeningAppointmentModel apt) {
    Color badgeColor = Colors.grey;
    if (apt.isConfirmed) badgeColor = AppColors.success;
    if (apt.status == 'Completed') badgeColor = Colors.blue;
    if (apt.isCancelled) badgeColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${apt.appointmentDate.year}-${apt.appointmentDate.month.toString().padLeft(2, '0')}-${apt.appointmentDate.day.toString().padLeft(2, '0')} • ${apt.timeSlot}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  apt.status,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(apt.purpose, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (apt.statusReason != null && apt.statusReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Reason: ${apt.statusReason}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (apt.staffReviewNotes != null && apt.staffReviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Staff Review: ${apt.staffReviewNotes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
