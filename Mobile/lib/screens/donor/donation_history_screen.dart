import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import 'donor_screening_screen.dart';
import 'milk_status_tracking_screen.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);
    final donor = donorProvider.donor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Donations'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => donorProvider.fetchMyDonorProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (donorProvider.hasDonorProfile && donor != null) ...[
                // Donor stats header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Donor Eligibility',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          StatusBadge(status: donor.eligibility),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Cumulative Donated',
                              value: donor.totalDonatedVolume.toStringAsFixed(0),
                              unit: 'mL',
                              icon: Icons.water_drop,
                              color: AppColors.accentPink,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              title: 'Total Sessions',
                              value: '${donor.donations.length}',
                              unit: 'times',
                              icon: Icons.event_available,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Donation Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                if (donor.donations.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No donations logged yet',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'When you attend milk letting activities or schedule pickups, your verified donated bags will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: donor.donations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = donor.donations[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MilkStatusTrackingScreen(donation: item),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.softPink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.water_drop, color: AppColors.accentPink, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.eventTitle ?? '${item.donationType} Milk Donation',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.eventDate != null
                                        ? DateFormat('MMMM d, yyyy').format(item.eventDate!)
                                        : 'Recorded Donation',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap to track milk processing status',
                                    style: TextStyle(fontSize: 11, color: AppColors.accentPink, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.totalVolume.toStringAsFixed(0)} mL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      );
                    },
                  ),
              ] else ...[
                // Not a donor yet CTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.volunteer_activism, size: 56, color: AppColors.accentPink),
                      const SizedBox(height: 16),
                      const Text(
                        'No Donor Profile Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You need to register as a breast milk donor before you can view your donation records.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DonorScreeningScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Apply as Milk Donor', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

