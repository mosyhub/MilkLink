import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/app_widgets.dart';
import 'book_screening_appointment_screen.dart';
import 'milk_status_tracking_screen.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  String _selectedStatus = 'All';
  DateTime? _selectedMonth;

  void _openDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        final now = DateTime.now();
        final months = List.generate(6, (i) => DateTime(now.year, now.month - i, 1));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Month',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                    ),
                    if (_selectedMonth != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedMonth = null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...months.map((m) {
                  final label = DateFormat('MMMM yyyy').format(m);
                  final isSelected = _selectedMonth != null &&
                      _selectedMonth!.year == m.year &&
                      _selectedMonth!.month == m.month;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryBlue, size: 20) : null,
                    onTap: () {
                      setState(() => _selectedMonth = m);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);
    final donor = donorProvider.donor;
    final donations = donor?.donations ?? [];

    // Filter
    final filtered = donations.where((d) {
      if (_selectedStatus != 'All') {
        if (!d.donationType.toLowerCase().contains(_selectedStatus.toLowerCase())) {
          return false;
        }
      }
      if (_selectedMonth != null && d.eventDate != null) {
        if (d.eventDate!.year != _selectedMonth!.year ||
            d.eventDate!.month != _selectedMonth!.month) {
          return false;
        }
      }
      return true;
    }).toList();

    // Summary calculations
    final totalVol = donor != null ? donor.totalDonatedVolume.toStringAsFixed(0) : '0';
    final totalCount = '${donations.length}';
    String lastDate = '—';
    if (donations.isNotEmpty) {
      final sorted = List<DonationRecord>.from(donations)
        ..sort((a, b) => (b.eventDate ?? DateTime(2000)).compareTo(a.eventDate ?? DateTime(2000)));
      if (sorted.first.eventDate != null) {
        lastDate = DateFormat('MMM d, yyyy').format(sorted.first.eventDate!);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppTopBar(),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => donorProvider.fetchMyDonorProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Screen Title
              const Text(
                'My Donations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 14),

              // Summary Card (Total volume, Total donations, Last donation date)
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Volume',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalVol ml',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sessions',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalCount,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Donation',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Filter Chips & Date Filter Button
              Row(
                children: [
                  Expanded(
                    child: FilterChips(
                      options: const ['All', 'Completed', 'Pending', 'Rejected'],
                      selected: _selectedStatus,
                      onSelected: (val) => setState(() => _selectedStatus = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openDateFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedMonth != null ? AppColors.softBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedMonth != null ? AppColors.primaryBlue : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _selectedMonth != null ? AppColors.primaryBlue : AppColors.textSecondary,
                          ),
                          if (_selectedMonth != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM yy').format(_selectedMonth!),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Donation Records List
              if (donorProvider.status == DonorStatus.loading && donations.isEmpty)
                ...List.generate(3, (i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LoadingSkeleton(height: 80, radius: 20),
                    ))
              else if (filtered.isEmpty)
                EmptyState(
                  message: 'No donations yet',
                  buttonText: 'Book slot',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookScreeningAppointmentScreen()),
                    );
                  },
                )
              else
                ...filtered.map((d) {
                  final dateFormatted = d.eventDate != null
                      ? DateFormat('MMM d, yyyy').format(d.eventDate!)
                      : 'Past Letting';
                  final volStr = '${d.totalVolume.toStringAsFixed(0)} ml';
                  final batchId = d.id.isNotEmpty ? 'ID: ${d.id.substring(d.id.length > 8 ? d.id.length - 8 : 0).toUpperCase()}' : 'Direct Batch';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MilkStatusTrackingScreen(donation: d),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                                    Text(
                                      volStr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  d.eventTitle ?? batchId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(status: d.donationType),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
