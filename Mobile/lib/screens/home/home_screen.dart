import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/milk_request_model.dart';
import '../../providers/articles_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/app_widgets.dart';
import '../auth/claim_record_screen.dart';
import '../content/announcement_detail_screen.dart';
import '../donor/book_screening_appointment_screen.dart';
import '../donor/chatbot_screen.dart';
import '../donor/donation_history_screen.dart';
import '../donor/donor_milk_request_screen.dart';
import '../donor/milk_pickup_schedule_screen.dart';
import '../donor/milk_status_tracking_screen.dart';
import '../donor/my_milk_requests_screen.dart';
import '../donor/my_screening_appointments_screen.dart';
import '../donor/returning_donor_search_screen.dart';
import '../main_navigation_screen.dart';
import '../staff/staff_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donorProvider = Provider.of<DonorProvider>(context);
    final articlesProvider = Provider.of<ArticlesProvider>(context);

    final user = authProvider.user;
    final donor = donorProvider.donor;
    final firstName = user?.name.first.isNotEmpty == true ? user!.name.first : 'Mother';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppTopBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.smart_toy_outlined, size: 24),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () async {
          await Future.wait([
            donorProvider.fetchMyDonorProfile(),
            articlesProvider.fetchAll(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Greeting
              Text(
                'Hello, $firstName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Together, saving lives one drop at a time.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Staff quick banner (if staff / admin)
              if (user?.isStaff == true || user?.isAdmin == true) ...[
                _buildStaffBanner(context),
                const SizedBox(height: 16),
              ],

              // 2. Eligibility Card
              _buildEligibilityCard(context, donorProvider, donor),
              const SizedBox(height: 24),

              // 3. Quick Actions
              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(context, authProvider.isDonorEligible, donor),
              const SizedBox(height: 24),

              const MyMilkRequestsCard(),
              const SizedBox(height: 24),

              // 4. Announcements
              SectionHeader(
                title: 'Announcements',
                actionLabel: 'See all',
                onAction: () {
                  MainNavigationScreen.switchTab(context, 3);
                },
              ),
              const SizedBox(height: 12),
              _buildAnnouncementsSection(context, articlesProvider),
              const SizedBox(height: 24),

              // 5. Donation Summary
              const SectionHeader(title: 'Donation Summary'),
              const SizedBox(height: 12),
              _buildDonationSummary(donor),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ELIGIBILITY CARD
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildEligibilityCard(
    BuildContext context,
    DonorProvider donorProvider,
    dynamic donor,
  ) {
    final hasProfile = donorProvider.hasDonorProfile && donor != null;
    final isEligible = donor?.eligibility == 'Eligible';
    final statusText = hasProfile ? (donor.eligibility ?? 'Pending') : 'Not Screened';
    final donorId = hasProfile ? (donor.donorId ?? 'Pending ID') : 'New Member';

    String helperLine;
    if (isEligible) {
      helperLine = 'Approved Donor: Authorized for home pickups & donations.';
    } else if (hasProfile) {
      helperLine = 'Screening in progress: Hospital verification required.';
    } else {
      helperLine = 'Hospital screening required before donating milk.';
    }

    return AppCard(
      gradient: const LinearGradient(
        colors: [AppColors.softBlue, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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
                    'Eligibility Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: $donorId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              StatusChip(status: statusText),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            helperLine,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookScreeningAppointmentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(110, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('Book slot'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyScreeningAppointmentsScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Appointments'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS GRID
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildQuickActionsGrid(
    BuildContext context,
    bool isEligible,
    dynamic donor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: [
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.calendar_month_outlined,
              label: 'Screening',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyScreeningAppointmentsScreen()),
                );
              },
            ),
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.local_shipping_outlined,
              label: 'Pickup',
              enabled: isEligible,
              disabledMessage: 'Requires completed hospital screening eligibility.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MilkPickupScheduleScreen()),
                );
              },
            ),
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.baby_changing_station_outlined,
              label: 'Request Milk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonorMilkRequestScreen()),
                );
              },
            ),
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.receipt_long_outlined,
              label: 'My Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyMilkRequestsScreen()),
                );
              },
            ),
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.qr_code_scanner_outlined,
              label: 'Returning',
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
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.timeline_outlined,
              label: 'Tracking',
              onTap: () {
                final donations = donor?.donations;
                final latest = (donations != null && donations.isNotEmpty) ? donations.first : null;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MilkStatusTrackingScreen(donation: latest)),
                );
              },
            ),
            _buildTile(
              context,
              width: itemWidth,
              icon: Icons.history_outlined,
              label: 'History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    String? disabledMessage,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (!enabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(disabledMessage ?? 'Requires eligibility.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primaryNavy,
                ),
              );
              return;
            }
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: AppColors.primaryNavy, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ANNOUNCEMENTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildAnnouncementsSection(
    BuildContext context,
    ArticlesProvider articlesProvider,
  ) {
    final list = articlesProvider.announcements.take(3).toList();

    if (articlesProvider.status == ArticlesStatus.loading && list.isEmpty) {
      return const LoadingSkeleton(height: 120);
    }

    if (list.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No announcements yet',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: PageView.builder(
        itemCount: list.length,
        controller: PageController(viewportFraction: 0.92),
        padEnds: false,
        itemBuilder: (context, i) {
          final ann = list[i];
          final dateStr = DateFormat('MMM d, yyyy').format(ann.createdAt);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnouncementDetailScreen(
                      announcement: ann,
                      isAdmin: false,
                      onMutated: () => articlesProvider.fetchAll(),
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ann.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ann.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DONATION SUMMARY
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDonationSummary(dynamic donor) {
    final vol = donor != null ? donor.totalDonatedVolume.toStringAsFixed(0) : '0';
    final count = '${donor?.donations.length ?? 0}';

    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Volume',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      vol,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ml',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Donations',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'sessions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffBanner(BuildContext context) {
    return AppCard(
      color: AppColors.primaryNavy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
        );
      },
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open Staff Dashboard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}

class MyMilkRequestsCard extends StatefulWidget {
  const MyMilkRequestsCard({super.key});

  @override
  State<MyMilkRequestsCard> createState() => _MyMilkRequestsCardState();
}

class _MyMilkRequestsCardState extends State<MyMilkRequestsCard> {
  bool _isLoading = true;
  List<MilkRequestModel> _requests = [];
  bool _loadFailed = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final response = await ApiClient.get(ApiConstants.myMilkRequests);
      if (!mounted) return;
      final requests = response is Map && response['requests'] is List
          ? (response['requests'] as List)
              .whereType<Map>()
              .map((item) => MilkRequestModel.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <MilkRequestModel>[];
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
          _loadError = error.toString().trim().isEmpty ? 'Request failed' : error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppCard(child: Center(child: CircularProgressIndicator()));
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Milk Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DonorMilkRequestScreen()),
                  );
                  _loadRequests();
                },
                child: const Text('Request Milk'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadFailed)
            Text(
              'Unable to load requests: $_loadError',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else if (_requests.isEmpty)
            const Text(
              'No milk requests submitted yet.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ..._requests.take(3).map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.requestNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                            Text(
                              '${request.recipientName} • ${request.formattedVolumeRequested}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(status: request.status),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
