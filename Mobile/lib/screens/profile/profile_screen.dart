import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../auth/login_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from MilkLink Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donorProvider = Provider.of<DonorProvider>(context);

    final user = authProvider.user;
    final donor = donorProvider.donor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // User Avatar & Name
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  UserAvatar(
                    radius: 36,
                    avatarUrl: user?.avatarUrl,
                    initial: user?.name.first.isNotEmpty == true
                        ? user!.name.first[0].toUpperCase()
                        : 'M',
                    backgroundColor: AppColors.softPink,
                    textColor: AppColors.accentPink,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name.fullName ?? 'Mother / Donor',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email?.isNotEmpty == true
                        ? user!.email!
                        : (user?.username.isNotEmpty == true
                            ? '@${user!.username}'
                            : ''),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softPink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donor != null
                          ? 'DONOR: ${donor.donorType.toUpperCase()}'
                          : (user?.role.toUpperCase() ?? 'REGISTERED USER'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryNavy),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      side: const BorderSide(color: AppColors.primaryNavy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Donor Information Section
            if (donor != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donor Information',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                        'Contact Number', user?.phone ?? donor.contactNumber ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildInfoRow('Home Address', donor.homeAddress.fullAddress),
                    const SizedBox(height: 10),
                    _buildInfoRow('Eligibility Status', donor.eligibility),
                    if (donor.children.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow('Child Name', donor.children.first.name),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Staff Portal Tile (if staff or admin)
            if (user?.isStaff == true || user?.isAdmin == true) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dashboard_customize, color: AppColors.primaryNavy, size: 22),
                  ),
                  title: const Text(
                    'Staff Dashboard',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  subtitle: const Text(
                    'Manage Donors, Recipients & Requests',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.primaryNavy),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // App Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_hospital_outlined,
                        color: AppColors.primaryNavy),
                    title: const Text('About MilkLink',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Pasig City Human Milk Bank',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'MilkLink Mobile',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Pasig-Pateros District Hospital Center for Women and Children.\n© 2026 Pasig City Human Milk Bank.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _confirmLogout(context, authProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
