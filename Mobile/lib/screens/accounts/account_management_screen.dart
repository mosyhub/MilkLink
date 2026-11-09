import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/account_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Staff tab state
  List<AccountModel> _staffAccounts = [];
  bool _staffLoading = true;
  String? _staffError;
  String _staffStatus = 'Active'; // Active | Deactivated | All
  final TextEditingController _staffSearch = TextEditingController();

  // Admin tab state
  List<AccountModel> _adminAccounts = [];
  bool _adminLoading = true;
  String? _adminError;
  String _adminStatus = 'Active';
  final TextEditingController _adminSearch = TextEditingController();

  // Other tab state
  List<AccountModel> _otherAccounts = [];
  bool _otherLoading = true;
  String? _otherError;
  String _otherStatus = 'All';
  final TextEditingController _otherSearch = TextEditingController();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _currentUserId = auth.user?.id;
      _fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _staffSearch.dispose();
    _adminSearch.dispose();
    _otherSearch.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    _fetchAccounts('Staff');
    _fetchAccounts('Admin');
    _fetchAccounts('Other');
  }

  Future<void> _fetchAccounts(String role) async {
    switch (role) {
      case 'Staff':
        setState(() { _staffLoading = true; _staffError = null; });
        break;
      case 'Admin':
        setState(() { _adminLoading = true; _adminError = null; });
        break;
      case 'Other':
        setState(() { _otherLoading = true; _otherError = null; });
        break;
    }

    try {
      final status = role == 'Staff' ? _staffStatus : role == 'Admin' ? _adminStatus : _otherStatus;
      final search = role == 'Staff' ? _staffSearch.text.trim() : role == 'Admin' ? _adminSearch.text.trim() : _otherSearch.text.trim();

      final uri = Uri.parse(ApiConstants.adminAccounts).replace(queryParameters: {
        'role': role,
        if (status != 'All') 'status': status,
        if (search.isNotEmpty) 'search': search,
        'limit': '100',
      });

      final res = await ApiClient.get(uri.toString());
      final List<AccountModel> parsed = [];
      if (res is Map && res['accounts'] is List) {
        for (final item in res['accounts']) {
          if (item is Map) {
            parsed.add(AccountModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (!mounted) return;
      switch (role) {
        case 'Staff':
          setState(() { _staffAccounts = parsed; _staffLoading = false; });
          break;
        case 'Admin':
          setState(() { _adminAccounts = parsed; _adminLoading = false; });
          break;
        case 'Other':
          setState(() { _otherAccounts = parsed; _otherLoading = false; });
          break;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (role) {
        case 'Staff': setState(() { _staffError = e.message; _staffLoading = false; }); break;
        case 'Admin': setState(() { _adminError = e.message; _adminLoading = false; }); break;
        case 'Other': setState(() { _otherError = e.message; _otherLoading = false; }); break;
      }
    } catch (e) {
      if (!mounted) return;
      final msg = 'Failed to load accounts. Check your connection.';
      switch (role) {
        case 'Staff': setState(() { _staffError = msg; _staffLoading = false; }); break;
        case 'Admin': setState(() { _adminError = msg; _adminLoading = false; }); break;
        case 'Other': setState(() { _otherError = msg; _otherLoading = false; }); break;
      }
    }
  }

  Future<void> _deactivate(AccountModel account) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block, color: AppColors.warning, size: 36),
        title: const Text('Deactivate Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deactivate "${account.fullName}"? They will not be able to log in.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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

    if (confirm != true) return;

    try {
      await ApiClient.put(ApiConstants.adminAccountDeactivate(account.id),
          data: {'reason': reasonCtrl.text.trim()});
      _showSnackbar('${account.fullName} deactivated.');
      _fetchAll();
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (e) {
      _showSnackbar('Failed to deactivate account.', isError: true);
    }
  }

  Future<void> _reactivate(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 36),
        title: const Text('Reactivate Account'),
        content: Text('Reactivate "${account.fullName}"? They will be able to log in again.'),
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

    if (confirm != true) return;

    try {
      await ApiClient.put(ApiConstants.adminAccountReactivate(account.id));
      _showSnackbar('${account.fullName} reactivated.');
      _fetchAll();
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (e) {
      _showSnackbar('Failed to reactivate account.', isError: true);
    }
  }

  Future<void> _delete(AccountModel account) async {
    if (account.id == _currentUserId) {
      _showSnackbar('You cannot delete your own account.', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 36),
        title: const Text('Delete Account Permanently'),
        content: Text(
          'Permanently delete "${account.fullName}" (@${account.username})?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.delete(ApiConstants.adminAccountById(account.id));
      _showSnackbar('Account deleted.');
      _fetchAll();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Has activity — suggest deactivate
        final deact = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 36),
            title: const Text('Cannot Delete'),
            content: Text('${e.message}\n\nWould you like to deactivate this account instead?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Deactivate Instead'),
              ),
            ],
          ),
        );
        if (deact == true) await _deactivate(account);
      } else {
        _showSnackbar(e.message, isError: true);
      }
    } catch (e) {
      _showSnackbar('Failed to delete account.', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _openDetail(AccountModel account) async {
    final mutated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailScreen(
          account: account,
          currentUserId: _currentUserId ?? '',
          onMutated: _fetchAll,
        ),
      ),
    );
    if (mutated == true) _fetchAll();
  }

  Future<void> _openCreate(String role) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AccountFormScreen(defaultRole: role)),
    );
    if (created == true) {
      _showSnackbar('Account created successfully.');
      _fetchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIdx = _tabController.index;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.badge_outlined), text: 'Staff'),
            Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Admin'),
            Tab(icon: Icon(Icons.people_outline), text: 'Others'),
          ],
        ),
      ),
      floatingActionButton: tabIdx < 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(tabIdx == 0 ? 'New Staff' : 'New Admin'),
              onPressed: () => _openCreate(tabIdx == 0 ? 'Staff' : 'Admin'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(
            role: 'Staff',
            accounts: _staffAccounts,
            loading: _staffLoading,
            error: _staffError,
            status: _staffStatus,
            searchCtrl: _staffSearch,
            onStatusChange: (v) { setState(() => _staffStatus = v); _fetchAccounts('Staff'); },
            onSearch: () => _fetchAccounts('Staff'),
          ),
          _buildTab(
            role: 'Admin',
            accounts: _adminAccounts,
            loading: _adminLoading,
            error: _adminError,
            status: _adminStatus,
            searchCtrl: _adminSearch,
            onStatusChange: (v) { setState(() => _adminStatus = v); _fetchAccounts('Admin'); },
            onSearch: () => _fetchAccounts('Admin'),
          ),
          _buildTab(
            role: 'Other',
            accounts: _otherAccounts,
            loading: _otherLoading,
            error: _otherError,
            status: _otherStatus,
            searchCtrl: _otherSearch,
            onStatusChange: (v) { setState(() => _otherStatus = v); _fetchAccounts('Other'); },
            onSearch: () => _fetchAccounts('Other'),
            isOther: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String role,
    required List<AccountModel> accounts,
    required bool loading,
    required String? error,
    required String status,
    required TextEditingController searchCtrl,
    required ValueChanged<String> onStatusChange,
    required VoidCallback onSearch,
    bool isOther = false,
  }) {
    return Column(
      children: [
        // Controls
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Status filter
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Active', label: Text('Active'), icon: Icon(Icons.check_circle_outline, size: 16)),
                        ButtonSegment(value: 'Deactivated', label: Text('Deactivated'), icon: Icon(Icons.block, size: 16)),
                        ButtonSegment(value: 'All', label: Text('All')),
                      ],
                      selected: {status},
                      onSelectionChanged: (v) => onStatusChange(v.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search name, email, or username...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { searchCtrl.clear(); onSearch(); },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSearch(),
                onChanged: (v) {
                  if (v.isEmpty) onSearch();
                  setState(() {}); // Update clear button
                },
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? _buildError(error, () => _fetchAccounts(role))
                  : accounts.isEmpty
                      ? _buildEmpty(role, status)
                      : RefreshIndicator(
                          onRefresh: () => _fetchAccounts(role),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 80, left: 16, right: 16),
                            itemCount: accounts.length,
                            itemBuilder: (ctx, i) => _buildAccountCard(accounts[i], isOther: isOther),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(AccountModel account, {bool isOther = false}) {
    final isMe = account.id == _currentUserId;
    final isActive = account.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('acc_${account.id}'),
        background: _swipeBg(
          color: isActive ? AppColors.warning : AppColors.success,
          icon: isActive ? Icons.block : Icons.check_circle_outline,
          label: isActive ? 'Deactivate' : 'Reactivate',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: isOther
            ? const SizedBox.shrink()
            : _swipeBg(
                color: AppColors.error,
                icon: Icons.delete_outline,
                label: 'Delete',
                alignment: Alignment.centerRight,
              ),
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.startToEnd) {
            if (isMe) {
              _showSnackbar('You cannot deactivate your own account.', isError: true);
              return false;
            }
            if (isActive) {
              await _deactivate(account);
            } else {
              await _reactivate(account);
            }
          } else if (!isOther) {
            if (isMe) {
              _showSnackbar('You cannot delete your own account.', isError: true);
            } else {
              await _delete(account);
            }
          }
          return false;
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetail(account),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? Colors.grey.shade200 : AppColors.warning.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar / Initials
                UserAvatar(
                  radius: 24,
                  avatarUrl: account.avatarUrl,
                  initial: account.initials.isNotEmpty ? account.initials : 'U',
                  backgroundColor: _roleColor(account.role).withValues(alpha: 0.15),
                  textColor: _roleColor(account.role),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.softBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('You', style: TextStyle(fontSize: 10, color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('@${account.username}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _rolePill(account.role),
                          const SizedBox(width: 6),
                          _statusPill(account.status),
                          if (account.mustChangePassword) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Must change password on next login',
                              child: Icon(Icons.key_outlined, size: 14, color: AppColors.warning),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialsWidget(AccountModel account) {
    return Center(
      child: Text(
        account.initials,
        style: TextStyle(
          color: _roleColor(account.role),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _swipeBg({required Color color, required IconData icon, required String label, required Alignment alignment}) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeft) Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (!isLeft) const SizedBox(width: 6),
          if (!isLeft) Icon(icon, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin': return AppColors.primaryNavy;
      case 'Staff': return AppColors.primaryBlue;
      default: return AppColors.textSecondary;
    }
  }

  Widget _rolePill(String role) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _statusPill(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Unable to load accounts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String role, String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              status == 'All' ? 'No $role accounts found.' : 'No $status $role accounts found.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 8),
            const Text('Try changing the status filter or search query.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

