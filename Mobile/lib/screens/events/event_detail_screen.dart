import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/letting_event_model.dart';
import '../../widgets/app_widgets.dart';

class EventDetailScreen extends StatefulWidget {
  final LettingEventModel event;
  final bool isRegistered;
  final VoidCallback? onToggleRegistration;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.isRegistered = false,
    this.onToggleRegistration,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late bool _registered;

  @override
  void initState() {
    super.initState();
    _registered = widget.isRegistered;
  }

  void _handleRegistration() {
    widget.onToggleRegistration?.call();
    setState(() => _registered = !_registered);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(event.details.date);
    final timeStr = '${event.details.time.start} – ${event.details.time.end}';
    final isPast = event.details.date.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Chip
                      StatusChip(status: isPast ? 'Past Event' : (_registered ? 'Registered' : 'Upcoming')),
                      const SizedBox(height: 12),

                      // Event Title
                      Text(
                        event.activity,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date & Time Card
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.softBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryNavy, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Venue Card
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.softBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.location_on_outlined, color: AppColors.primaryNavy, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.venue.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event.venue.fullAddress,
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Short Description
                      const Text(
                        'About This Activity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Community Milk Letting Event hosted by Pasig City Human Milk Bank. Qualified donors are invited to donate breastmilk to help infants in critical need across neonatal care units.',
                        style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Primary Action
              if (!isPast)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _registered ? AppColors.error : AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _registered ? 'Cancel Registration' : 'Register for Event',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
