import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/session_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _showServerSettings(BuildContext context) {
    final urlController = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the backend API host. Use 10.0.2.2:4000 for Android Emulator, or your PC IP (e.g. 192.168.1.X:4000) for physical phone.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              ApiConstants.baseUrl = urlController.text.trim();
              await SessionManager.saveCustomBaseUrl(ApiConstants.baseUrl);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from TCHMB Portal?'),
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
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.softPink,
                    child: Text(
                      user?.name.first.isNotEmpty == true ? user!.name.first[0].toUpperCase() : 'M',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentPink),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name.fullName ?? 'Mother / Donor',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
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
                      donor != null ? 'DONOR: ${donor.donorType.toUpperCase()}' : 'REGISTERED USER',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPink,
                      ),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow('Contact Number', user?.phone ?? donor.contactNumber ?? 'N/A'),
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

            // App Settings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_ethernet, color: AppColors.primaryNavy),
                    title: const Text('Server Connection URL', style: TextStyle(fontSize: 14)),
                    subtitle: Text(ApiConstants.baseUrl, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showServerSettings(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.local_hospital_outlined, color: AppColors.primaryNavy),
                    title: const Text('About TCHMB', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Taguig City Human Milk Bank', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'TCHMB Mobile',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Taguig-Pateros District Hospital Center for Women and Children.\n© 2026 Taguig City Human Milk Bank.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Sign Out', style: TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.w600)),
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
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

