import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/app_widgets.dart';
import '../auth/claim_record_screen.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/login_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildAvatar(String? avatarUrl, String initial) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Text(
        initial,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
      );
    }

    if (avatarUrl.startsWith('data:image')) {
      try {
        final commaIdx = avatarUrl.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(avatarUrl.substring(commaIdx + 1));
          return Image.memory(
            bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              initial,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
          );
        }
      } catch (_) {}
    }

    return Image.network(
      avatarUrl,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Text(
        initial,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from MilkLink?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
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

    String initial = 'M';
    if (user != null && user.name.first.isNotEmpty) {
      initial = user.name.first[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
            // User Avatar Card
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.softBlue,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: _buildAvatar(user?.avatarUrl, initial),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name.fullName ?? 'Mother / Donor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email?.isNotEmpty == true
                        ? user!.email!
                        : (user?.username.isNotEmpty == true ? '@${user!.username}' : ''),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (donor != null) ...[
                    const SizedBox(height: 8),
                    StatusChip(status: donor.eligibility),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Options Card (3-5 plain rows)
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildProfileRow(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _buildProfileRow(
                    context,
                    icon: Icons.lock_reset_outlined,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                  ),
                  if (donor == null) ...[
                    const Divider(height: 1, indent: 56, color: AppColors.border),
                    _buildProfileRow(
                      context,
                      icon: Icons.qr_code_scanner_outlined,
                      title: 'Claim Hospital Account',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClaimRecordScreen()),
                        );
                      },
                    ),
                  ],
                  if (user?.isStaff == true || user?.isAdmin == true) ...[
                    const Divider(height: 1, indent: 56, color: AppColors.border),
                    _buildProfileRow(
                      context,
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Staff Dashboard',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
                        );
                      },
                    ),
                  ],
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _buildProfileRow(
                    context,
                    icon: Icons.info_outline,
                    title: 'About MilkLink',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'MilkLink Mobile',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Pasig City Human Milk Bank.\nPasig City General Hospital.',
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _buildProfileRow(
                    context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    titleColor: AppColors.error,
                    iconColor: AppColors.error,
                    showChevron: false,
                    onTap: () => _confirmLogout(context, authProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryNavy).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor ?? AppColors.primaryNavy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
