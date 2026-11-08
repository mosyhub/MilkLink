import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/articles_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/event_card.dart';
import '../../widgets/article_card.dart';
import '../notifications/notifications_screen.dart';
import '../events/event_detail_screen.dart';
import '../articles/article_detail_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../donor/returning_donor_search_screen.dart';
import '../donor/milk_pickup_schedule_screen.dart';
import '../donor/donor_milk_request_screen.dart';
import '../donor/chatbot_screen.dart';
import '../donor/book_screening_appointment_screen.dart';
import '../donor/my_screening_appointments_screen.dart';
import '../donor/donation_history_screen.dart';
import '../donor/milk_status_tracking_screen.dart';
import '../auth/claim_record_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donorProvider = Provider.of<DonorProvider>(context);
    final eventsProvider = Provider.of<EventsProvider>(context);
    final articlesProvider = Provider.of<ArticlesProvider>(context);
    final notifProvider = Provider.of<NotificationsProvider>(context);

    final user = authProvider.user;
    final donor = donorProvider.donor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.softPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism, color: AppColors.accentPink, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'MilkLink Portal',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (notifProvider.unseenCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifProvider.unseenCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            donorProvider.fetchMyDonorProfile(),
            eventsProvider.fetchUpcomingEvents(),
            articlesProvider.fetchAll(),
            notifProvider.fetchNotifications(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                'Welcome, ${user?.name.first ?? "Mother"}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Together, saving lives one drop at a time.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Staff Management Banner (if staff/admin)
              if (user?.isStaff == true || user?.isAdmin == true) ...[
                _buildStaffDashboardBanner(context),
                const SizedBox(height: 20),
              ],

              // Donor Status Card or Application CTA
              if (donorProvider.hasDonorProfile && donor != null) ...[
                _buildDonorStatusCard(context, donor),
              ] else ...[
                _buildBecomeDonorCTA(context),
              ],

              const SizedBox(height: 18),

              // MilkLink Quick Action Grid for Donors
              _buildDonorQuickActions(context),

              const SizedBox(height: 24),

              // Statistics Section
              const Text(
                'Donation Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Donated',
                      value: donor != null ? donor.totalDonatedVolume.toStringAsFixed(0) : '0',
                      unit: 'mL',
                      icon: Icons.water_drop,
                      color: AppColors.accentPink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Donation Sessions',
                      value: '${donor?.donations.length ?? 0}',
                      unit: 'times',
                      icon: Icons.event_available,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Upcoming Milk Letting Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Milk Letting',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (eventsProvider.status == EventsStatus.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (eventsProvider.events.isNotEmpty)
                EventCard(
                  event: eventsProvider.events.first,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(event: eventsProvider.events.first),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No upcoming milk letting events scheduled at this moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              // Educational Articles & Resources
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Milk Banking & Breastfeeding',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (articlesProvider.articles.isNotEmpty) ...[
                ArticleCard(
                  article: articlesProvider.articles.first,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(article: articlesProvider.articles.first),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffDashboardBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Management Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Donors • Recipients • Milk Requests',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_customize, size: 18),
              label: const Text(
                'Open Staff Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorStatusCard(BuildContext context, dynamic donor) {
    final isEligible = donor.eligibility == 'Eligible';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEligible ? AppColors.success.withValues(alpha: 0.5) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donor Eligibility Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${donor.donorId ?? "Pending"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              StatusBadge(status: donor.eligibility),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(
                isEligible ? Icons.verified_user : Icons.pending_actions,
                size: 16,
                color: isEligible ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isEligible
                      ? 'Approved Donor: You are authorized to schedule home pickups & donate milk.'
                      : 'Screening in progress: Hospital visit and staff verification required before donation.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isEligible ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyScreeningAppointmentsScreen()),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryNavy),
                  label: const Text('Appointments', style: TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isEligible)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookScreeningAppointmentScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle, size: 16),
                    label: const Text('Book Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBecomeDonorCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Hospital Donor Screening',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'New donors must undergo hospital screening and receive authorized medical approval before donating milk. Schedule your clinic appointment below.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookScreeningAppointmentScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Book Screening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyScreeningAppointmentsScreen()),
                  );
                },
                icon: const Icon(Icons.event_note, size: 18, color: Colors.white),
                label: const Text('My Visits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClaimRecordScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_2, size: 18, color: Colors.white70),
              label: const Text(
                'Already screened by staff? Claim Existing Account',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorQuickActions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final isEligible = authProvider.isDonorEligible;
    final donor = donorProvider.donor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Donor & Recipient Services',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
              icon: const Icon(Icons.smart_toy, size: 16, color: AppColors.accentPink),
              label: const Text('AI Assistant', style: TextStyle(color: AppColors.accentPink)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            // 1. Screening Appointments (User can schedule hospital screening)
            _buildActionTile(
              context,
              title: 'Hospital Screening',
              subtitle: 'Book clinic visit',
              icon: Icons.calendar_month,
              color: AppColors.accentPink,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyScreeningAppointmentsScreen()),
                );
              },
            ),

            // 2. Milk Pickup (Only when donor is eligible)
            _buildActionTile(
              context,
              title: 'Milk Pickup',
              subtitle: isEligible ? '5 Pasig Outposts' : 'Requires eligibility',
              icon: Icons.local_shipping,
              color: isEligible ? const Color(0xFF0284C7) : Colors.grey,
              onTap: () {
                if (!isEligible) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Milk pickup scheduling requires completed hospital screening and medical approval.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookScreeningAppointmentScreen()),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MilkPickupScheduleScreen()),
                );
              },
            ),

            // 3. Request Milk (Any registered user can request milk without donor screening)
            _buildActionTile(
              context,
              title: 'Request Milk',
              subtitle: 'Recipient intake',
              icon: Icons.baby_changing_station,
              color: const Color(0xFF059669),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonorMilkRequestScreen()),
                );
              },
            ),

            // 4. Claim Existing Hospital Account or Returning Donor Search
            _buildActionTile(
              context,
              title: donor == null ? 'Claim Account' : 'Returning Donor',
              subtitle: donor == null ? 'Enter QR / Token' : 'Lookup ID / QR',
              icon: donor == null ? Icons.qr_code_scanner : Icons.repeat,
              color: AppColors.primaryNavy,
              onTap: () {
                if (donor == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClaimRecordScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReturningDonorSearchScreen()),
                  );
                }
              },
            ),

            // 5. Milk Status Tracking
            _buildActionTile(
              context,
              title: 'Milk Tracking',
              subtitle: 'Batch timeline',
              icon: Icons.timeline,
              color: const Color(0xFF7C3AED),
              onTap: () {
                final donorProv = Provider.of<DonorProvider>(context, listen: false);
                final donations = donorProv.donor?.donations;
                final latestDonation = (donations != null && donations.isNotEmpty) ? donations.first : null;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MilkStatusTrackingScreen(donation: latestDonation)),
                );
              },
            ),

            // 6. Donation History
            _buildActionTile(
              context,
              title: 'Donation History',
              subtitle: 'Volumes & logs',
              icon: Icons.history,
              color: const Color(0xFFD97706),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

