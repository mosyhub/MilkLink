import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/account_model.dart';
import '../../widgets/user_avatar.dart';

class AccountDetailScreen extends StatefulWidget {
  final AccountModel account;
  final String currentUserId;
  final VoidCallback onMutated;

  const AccountDetailScreen({
    super.key,
    required this.account,
    required this.currentUserId,
    required this.onMutated,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late AccountModel _account;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _refreshAccount();
  }

  bool get _isSelf => widget.currentUserId == _account.id;
  bool get _isOtherRole => _account.role != 'Staff' && _account.role != 'Admin';

  Future<void> _refreshAccount() async {
    try {
      final res = await ApiClient.get(ApiConstants.adminAccountById(_account.id));
      if (res['success'] == true && res['account'] != null) {
        if (mounted) {
          setState(() {
            _account = AccountModel.fromJson(res['account']);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _changeRole() async {
    if (_isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot change your own role.')),
      );
      return;
    }

    String selectedRole = _account.role == 'Admin' ? 'Staff' : 'Admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Account Role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change role for ${_account.fullName}:'),
                  const SizedBox(height: 12),
                  Text('Current Role: ${_account.role}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'New Role',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.put(
  ApiConstants.adminAccountRole(_account.id),
  data: {'role': selectedRole},
);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $selectedRole for ${_account.fullName}')),
        );
        widget.onMutated();
        await _refreshAccount();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change role: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deactivate() async {
    if (_isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot deactivate your own account.')),
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to deactivate ${_account.fullName}?'),
            const SizedBox(height: 8),
            const Text(
              'The user will be immediately logged out and cannot sign in.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.put(
  ApiConstants.adminAccountDeactivate(_account.id),
  data: {'reason': reasonCtrl.text.trim()},
);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_account.fullName} has been deactivated.')),
        );
        widget.onMutated();
        await _refreshAccount();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: Text('Reactivate ${_account.fullName}? They will be able to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.put(
  ApiConstants.adminAccountReactivate(_account.id),
);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_account.fullName} is now active.')),
        );
        widget.onMutated();
        await _refreshAccount();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    if (_isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to permanently delete ${_account.fullName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.delete(ApiConstants.adminAccountById(_account.id));
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_account.fullName} deleted.')),
        );
        widget.onMutated();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('activity records')) {
        _showActivityBlockedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showActivityBlockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot Delete Account'),
        content: const Text(
          'This account has activity records (schedules, collections, or audit logs).\n\nDeactivate it instead to preserve audit history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              Navigator.pop(ctx);
              _deactivate();
            },
            child: const Text('Deactivate Instead'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_account.fullName),
        actions: [
          if (!_isOtherRole && !_isSelf)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'role') _changeRole();
                if (val == 'deactivate') _deactivate();
                if (val == 'reactivate') _reactivate();
                if (val == 'delete') _delete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'role', child: Text('Edit Role')),
                if (_account.isActive)
                  const PopupMenuItem(value: 'deactivate', child: Text('Deactivate'))
                else
                  const PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Account', style: TextStyle(color: AppColors.error)),
                ),
              ],
            )
          else if (_isOtherRole)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'deactivate') _deactivate();
                if (val == 'reactivate') _reactivate();
              },
              itemBuilder: (ctx) => [
                if (_account.isActive)
                  const PopupMenuItem(value: 'deactivate', child: Text('Deactivate'))
                else
                  const PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAccount,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  if (_account.isDeactivated) ...[
                    _buildDeactivationCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildActivitySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final roleColor = _account.role == 'Admin' ? AppColors.primaryNavy : AppColors.primaryBlue;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            UserAvatar(
              radius: 36,
              avatarUrl: _account.avatarUrl,
              initial: _account.initials.isNotEmpty ? _account.initials : 'U',
              backgroundColor: roleColor.withValues(alpha: 0.15),
              textColor: roleColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _account.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('@${_account.username}', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _account.role,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: roleColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _account.isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _account.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _account.isActive ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _infoRow(Icons.email_outlined, 'Email', _account.email ?? 'No email set'),
            const SizedBox(height: 12),
            _infoRow(Icons.phone_outlined, 'Contact Number', _account.phone),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today_outlined, 'Created Date', _account.formattedCreatedAt),
            const SizedBox(height: 12),
            _infoRow(Icons.access_time_outlined, 'Last Login', _account.formattedLastLogin),
            if (_account.mustChangePassword) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User must change password on first login.',
                        style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeactivationCard() {
    return Card(
      elevation: 0,
      color: AppColors.warning.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Deactivation Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${_account.deactivationReason?.isNotEmpty == true ? _account.deactivationReason : "No reason provided."}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity & Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_account.auditHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('No activity history found.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ..._account.auditHistory.map((entry) => _buildAuditItem(entry)),
      ],
    );
  }

  Widget _buildAuditItem(AccountAuditEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8EEF5),
          child: Icon(Icons.history, color: AppColors.primaryNavy, size: 20),
        ),
        title: Text(entry.actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By: ${entry.actorName} â€¢ ${entry.formattedTimestamp}', style: const TextStyle(fontSize: 11)),
            if (entry.reason?.isNotEmpty == true)
              Text('Reason: ${entry.reason}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

