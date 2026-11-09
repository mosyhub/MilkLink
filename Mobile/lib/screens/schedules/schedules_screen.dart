import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/schedule_model.dart';
import 'schedule_detail_screen.dart';
import 'schedule_form_screen.dart';

class SchedulesScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SchedulesScreen({super.key, this.onBack});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Master lists fetched from server
  List<ScheduleModel> _activeSchedules = [];
  List<ScheduleModel> _archivedSchedules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.get(ApiConstants.schedules),
        ApiClient.get(ApiConstants.archivedSchedules),
      ]);

      final activeList = _parseSchedules(responses[0]);
      final archivedList = _parseSchedules(responses[1]);

      if (mounted) {
        setState(() {
          _activeSchedules = activeList;
          _archivedSchedules = archivedList;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load schedules. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  List<ScheduleModel> _parseSchedules(dynamic res) {
    if (res is Map && res['schedules'] is List) {
      final list = res['schedules'] as List;
      return list
          .whereType<Map>()
          .map((m) => ScheduleModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  Future<void> _archiveSchedule(ScheduleModel schedule) async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Schedule',
      content: 'Are you sure you want to archive "${schedule.displayName}"?',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteSchedule(schedule.id));
      _showSnackbar('Schedule archived.');
      await _fetchSchedules();
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to archive schedule.', isError: true);
    }
  }

  Future<void> _restoreSchedule(ScheduleModel schedule) async {
    try {
      await ApiClient.put(ApiConstants.restoreSchedule(schedule.id));
      _showSnackbar('Schedule restored to active list.');
      await _fetchSchedules();
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to restore schedule.', isError: true);
    }
  }

  Future<void> _deleteSchedule(ScheduleModel schedule) async {
    final confirm = await _showConfirmDialog(
      title: 'Permanently Delete',
      content: 'Permanently delete "${schedule.displayName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.scheduleById(schedule.id));
      _showSnackbar('Schedule deleted permanently.');
      await _fetchSchedules();
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (_) {
      _showSnackbar('Failed to delete schedule.', isError: true);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
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

  Future<void> _openCreateForm(String kind) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          initialKind: kind,
          allActiveSchedules: _activeSchedules,
        ),
      ),
    );

    if (created == true) {
      _showSnackbar('$kind schedule created successfully.');
      await _fetchSchedules();
    }
  }

  Future<void> _openDetail(ScheduleModel schedule) async {
    final mutated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailScreen(
          initialSchedule: schedule,
          allActiveSchedules: _activeSchedules,
          onMutated: _fetchSchedules,
        ),
      ),
    );

    if (mutated == true) {
      await _fetchSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Schedules', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: widget.onBack,
              )
            : null,
        automaticallyImplyLeading: widget.onBack == null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryNavy,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.event_outlined), text: 'Event Schedules'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Pickup Schedules'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ScheduleTabView(
                      kind: 'Event',
                      activeSchedules: _activeSchedules.where((s) => s.isEvent).toList(),
                      archivedSchedules: _archivedSchedules.where((s) => s.isEvent).toList(),
                      onRefresh: _fetchSchedules,
                      onTapItem: _openDetail,
                      onArchive: _archiveSchedule,
                      onRestore: _restoreSchedule,
                      onDelete: _deleteSchedule,
                      onCreate: () => _openCreateForm('Event'),
                    ),
                    _ScheduleTabView(
                      kind: 'Pickup',
                      activeSchedules: _activeSchedules.where((s) => s.isPickup).toList(),
                      archivedSchedules: _archivedSchedules.where((s) => s.isPickup).toList(),
                      onRefresh: _fetchSchedules,
                      onTapItem: _openDetail,
                      onArchive: _archiveSchedule,
                      onRestore: _restoreSchedule,
                      onDelete: _deleteSchedule,
                      onCreate: () => _openCreateForm('Pickup'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Unable to load schedules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 48),
              ),
              onPressed: _fetchSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTabView extends StatefulWidget {
  final String kind; // 'Event' or 'Pickup'
  final List<ScheduleModel> activeSchedules;
  final List<ScheduleModel> archivedSchedules;
  final Future<void> Function() onRefresh;
  final ValueChanged<ScheduleModel> onTapItem;
  final ValueChanged<ScheduleModel> onArchive;
  final ValueChanged<ScheduleModel> onRestore;
  final ValueChanged<ScheduleModel> onDelete;
  final VoidCallback onCreate;

  const _ScheduleTabView({
    required this.kind,
    required this.activeSchedules,
    required this.archivedSchedules,
    required this.onRefresh,
    required this.onTapItem,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
    required this.onCreate,
  });

  @override
  State<_ScheduleTabView> createState() => _ScheduleTabViewState();
}

class _ScheduleTabViewState extends State<_ScheduleTabView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showArchived = false;
  String _searchQuery = '';

  // Pagination support
  static const int _pageSize = 10;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  void _loadMore() {
    final filtered = _getFilteredList();
    if (_isLoadingMore || _currentPage * _pageSize >= filtered.length) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<ScheduleModel> _getFilteredList() {
    final source = _showArchived ? widget.archivedSchedules : widget.activeSchedules;
    if (_searchQuery.isEmpty) return source;

    final q = _searchQuery.toLowerCase();
    return source.where((s) {
      final matchName = s.displayName.toLowerCase().contains(q);
      final matchAddress = s.displayAddress.toLowerCase().contains(q);
      final matchStatus = s.effectiveStatus.toLowerCase().contains(q);
      final matchDesc = s.description.toLowerCase().contains(q);
      final matchDate = s.displayDate.toLowerCase().contains(q);
      return matchName || matchAddress || matchStatus || matchDesc || matchDate;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
      case 'Approved':
        return AppColors.primaryBlue;
      case 'Completed':
      case 'Picked Up':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      case 'Pending':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredList();
    final pagedItems = filtered.take(_currentPage * _pageSize).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.kind.toLowerCase()} schedules...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Active / Archived FilterChips / SegmentedButton
                Row(
                  children: [
                    FilterChip(
                      selected: !_showArchived,
                      label: Text('Active (${widget.activeSchedules.length})'),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: !_showArchived ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: AppColors.primaryNavy,
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.surface,
                      onSelected: (val) {
                        setState(() {
                          _showArchived = false;
                          _currentPage = 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showArchived,
                      label: Text('Archived (${widget.archivedSchedules.length})'),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _showArchived ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: AppColors.primaryNavy,
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.surface,
                      onSelected: (val) {
                        setState(() {
                          _showArchived = true;
                          _currentPage = 1;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Schedule List View with lazy loading and pull to refresh
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryNavy,
              onRefresh: widget.onRefresh,
              child: pagedItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: pagedItems.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == pagedItems.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                              ),
                            ),
                          );
                        }
                        final item = pagedItems[index];
                        return _buildDismissibleItem(item);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        onPressed: widget.onCreate,
        icon: const Icon(Icons.add),
        label: Text('New ${widget.kind}'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showArchived ? Icons.archive_outlined : Icons.calendar_today_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching ${widget.kind.toLowerCase()} schedules'
                  : (_showArchived
                      ? 'No archived ${widget.kind.toLowerCase()} schedules'
                      : 'No schedules yet'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with a different term.'
                  : (_showArchived
                      ? 'Archived schedules will appear here.'
                      : 'Create a new schedule by tapping the button below.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleItem(ScheduleModel item) {
    final statusColor = _getStatusColor(item.effectiveStatus);

    return Dismissible(
      key: Key('sched_${item.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          widget.onDelete(item);
          return false; // let callback trigger reload
        } else {
          // Archive or Restore
          if (!_showArchived) {
            widget.onArchive(item);
          } else {
            widget.onRestore(item);
          }
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: !_showArchived ? AppColors.warning : AppColors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(!_showArchived ? Icons.archive : Icons.unarchive, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              !_showArchived ? 'Archive' : 'Restore',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onTapItem(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title and Status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        item.effectiveStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date and Time (shown on every card as required)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 15, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    Text(
                      item.displayDate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 15, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.displayTimeRange,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location / Address
                if (item.displayAddress.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.displayAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (item.isPickup && item.totalVolume > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.water_drop_outlined, size: 15, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        '${item.totalVolume.toStringAsFixed(0)} ml',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
