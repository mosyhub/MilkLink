import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';
import 'collection_detail_screen.dart';
import 'fridge_detail_screen.dart';
import 'fridge_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab 0: Collections State
  List<CollectionModel> _collections = [];
  bool _isLoadingCollections = true;
  String? _collectionsError;
  int _collectionsArchiveFilter = 0; // 0 = Active, 1 = Archived
  String _selectedStatusFilter = 'All';
  DateTimeRange? _selectedDateRange;
  final TextEditingController _collectionSearchController = TextEditingController();

  // Tab 1: Refrigerators State
  List<FridgeModel> _activeFridges = [];
  List<FridgeModel> _archivedFridges = [];
  bool _isLoadingFridges = true;
  String? _fridgesError;
  int _fridgesArchiveFilter = 0; // 0 = Active, 1 = Archived
  final TextEditingController _fridgeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchCollections();
    _fetchFridges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _collectionSearchController.dispose();
    _fridgeSearchController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COLLECTIONS DATA FETCHING & ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _fetchCollections() async {
    setState(() {
      _isLoadingCollections = true;
      _collectionsError = null;
    });

    try {
      final isArchived = _collectionsArchiveFilter == 1;
      final queryParams = <String, String>{
        'isArchived': isArchived ? 'true' : 'false',
      };
      if (_selectedStatusFilter != 'All') {
        queryParams['status'] = _selectedStatusFilter;
      }
      if (_selectedDateRange != null) {
        queryParams['startDate'] = _selectedDateRange!.start.toIso8601String();
        queryParams['endDate'] = _selectedDateRange!.end.toIso8601String();
      }
      if (_collectionSearchController.text.trim().isNotEmpty) {
        queryParams['search'] = _collectionSearchController.text.trim();
      }

      final uri = Uri.parse(ApiConstants.collections).replace(queryParameters: queryParams);
      final res = await ApiClient.get(uri.toString());

      final List<CollectionModel> parsed = [];
      if (res is Map && res['collections'] is List) {
        for (final item in res['collections']) {
          if (item is Map) {
            parsed.add(CollectionModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (mounted) {
        setState(() {
          _collections = parsed;
          _isLoadingCollections = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _collectionsError = e.message;
          _isLoadingCollections = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _collectionsError = 'Failed to load collections. Please check your connection.';
          _isLoadingCollections = false;
        });
      }
    }
  }

  Future<void> _archiveCollection(CollectionModel col) async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Collection',
      content: 'Archive collection for "${col.displayName}"? This will not remove milk already stored in refrigerators.',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteCollection(col.id));
      _showSnackbar('Collection archived.');
      await _fetchCollections();
    } catch (e) {
      _showSnackbar('Failed to archive collection: $e', isError: true);
    }
  }

  Future<void> _restoreCollection(CollectionModel col) async {
    final confirm = await _showConfirmDialog(
      title: 'Restore Collection',
      content: 'Restore collection record for "${col.displayName}"?',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primaryBlue,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.restoreCollection(col.id));
      _showSnackbar('Collection restored.');
      await _fetchCollections();
    } catch (e) {
      _showSnackbar('Failed to restore collection: $e', isError: true);
    }
  }

  Future<void> _deleteCollection(CollectionModel col) async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Collection Permanently',
      content: 'Are you sure you want to permanently delete this collection record for "${col.displayName}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.collectionById(col.id));
      _showSnackbar('Collection permanently deleted.');
      await _fetchCollections();
    } catch (e) {
      _showSnackbar('Failed to delete collection: $e', isError: true);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REFRIGERATORS DATA FETCHING & ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _fetchFridges() async {
    setState(() {
      _isLoadingFridges = true;
      _fridgesError = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.get(ApiConstants.fridges),
        ApiClient.get(ApiConstants.archivedFridges),
      ]);

      final active = _parseFridges(responses[0]);
      final archived = _parseFridges(responses[1]);

      if (mounted) {
        setState(() {
          _activeFridges = active;
          _archivedFridges = archived;
          _isLoadingFridges = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _fridgesError = e.message;
          _isLoadingFridges = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fridgesError = 'Failed to load refrigerators. Please check your connection.';
          _isLoadingFridges = false;
        });
      }
    }
  }

  List<FridgeModel> _parseFridges(dynamic res) {
    if (res is Map && res['fridges'] is List) {
      return (res['fridges'] as List)
          .whereType<Map>()
          .map((m) => FridgeModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  Future<void> _archiveFridge(FridgeModel fridge) async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Refrigerator',
      content: 'Are you sure you want to archive "${fridge.name}"?',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteFridge(fridge.id));
      _showSnackbar('Refrigerator archived.');
      await _fetchFridges();
    } catch (e) {
      _showSnackbar('Failed to archive: $e', isError: true);
    }
  }

  Future<void> _restoreFridge(FridgeModel fridge) async {
    final confirm = await _showConfirmDialog(
      title: 'Restore Refrigerator',
      content: 'Restore "${fridge.name}" to active refrigerators?',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primaryBlue,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.restoreFridge(fridge.id));
      _showSnackbar('Refrigerator restored.');
      await _fetchFridges();
    } catch (e) {
      _showSnackbar('Failed to restore: $e', isError: true);
    }
  }

  Future<void> _deleteFridge(FridgeModel fridge) async {
    if (fridge.entryCount > 0) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40),
          title: const Text('Delete Blocked'),
          content: Text(
            'Cannot delete refrigerator "${fridge.name}" while it holds ${fridge.entryCount} entries. Please move or remove the entries first.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      title: 'Delete Refrigerator Permanently',
      content: 'Are you sure you want to permanently delete "${fridge.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.fridgeById(fridge.id));
      _showSnackbar('Refrigerator deleted.');
      await _fetchFridges();
    } catch (e) {
      _showSnackbar('$e', isError: true);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPERS & DIALOGS
  // ───────────────────────────────────────────────────────────────────────────

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

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD UI
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Milk Bank Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.primaryBlue,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.water_drop_outlined), text: 'Collections'),
            Tab(icon: Icon(Icons.kitchen_outlined), text: 'Refrigerators'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1 && _fridgesArchiveFilter == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Refrigerator'),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FridgeFormScreen()),
                );
                if (created == true) {
                  _showSnackbar('Refrigerator created successfully.');
                  await _fetchFridges();
                }
              },
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollectionsTab(),
          _buildRefrigeratorsTab(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: COLLECTIONS TAB
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCollectionsTab() {
    return Column(
      children: [
        // Filter bar: Active/Archived & Search & Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active / Archived Segmented Button
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Active Collections'), icon: Icon(Icons.inventory_2)),
                        ButtonSegment(value: 1, label: Text('Archived'), icon: Icon(Icons.archive_outlined)),
                      ],
                      selected: {_collectionsArchiveFilter},
                      onSelectionChanged: (set) {
                        setState(() => _collectionsArchiveFilter = set.first);
                        _fetchCollections();
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Bar
              TextField(
                controller: _collectionSearchController,
                decoration: InputDecoration(
                  hintText: 'Search donor name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _collectionSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _collectionSearchController.clear();
                            _fetchCollections();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _fetchCollections(),
              ),
              const SizedBox(height: 10),

              // Status Dropdown and Date Range Filter
              Row(
                children: [
                  // Status Filter Dropdown
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatusFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('Status: All', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Collected', child: Text('Collected', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Stored', child: Text('Stored', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'Dispensed', child: Text('Dispensed', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _selectedStatusFilter = val);
                            _fetchCollections();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Date Range Button
                  Expanded(
                    flex: 5,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryNavy,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedDateRange = picked);
                          _fetchCollections();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedDateRange != null ? AppColors.softBlue : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedDateRange != null ? AppColors.primaryBlue : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _selectedDateRange != null ? AppColors.primaryNavy : AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedDateRange == null
                                    ? 'Date Range'
                                    : '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedDateRange != null ? AppColors.primaryNavy : AppColors.primaryBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedDateRange != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedDateRange = null);
                                  _fetchCollections();
                                },
                                child: const Icon(Icons.close, size: 16, color: AppColors.primaryNavy),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List View with Pull-to-refresh
        Expanded(
          child: _isLoadingCollections
              ? const Center(child: CircularProgressIndicator())
              : _collectionsError != null
                  ? _buildErrorView(_collectionsError!, _fetchCollections)
                  : _collections.isEmpty
                      ? _buildEmptyView(
                          _collectionsArchiveFilter == 1
                              ? 'No archived collections found.'
                              : 'No collection records found.',
                          subtitle: 'Collections are automatically recorded when a pickup schedule is marked "Picked Up".',
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchCollections,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 80, left: 16, right: 16),
                            itemCount: _collections.length,
                            itemBuilder: (context, index) {
                              final item = _collections[index];
                              return _buildCollectionCard(item);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(CollectionModel item) {
    final isArchived = item.isDeleted || _collectionsArchiveFilter == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('col_${item.id}'),
        background: _buildSwipeBackground(
          color: isArchived ? AppColors.primaryBlue : AppColors.warning,
          icon: isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          alignment: Alignment.centerLeft,
          label: isArchived ? 'Restore' : 'Archive',
        ),
        secondaryBackground: _buildSwipeBackground(
          color: AppColors.error,
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
          label: 'Delete',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (isArchived) {
              await _restoreCollection(item);
            } else {
              await _archiveCollection(item);
            }
            return false;
          } else {
            await _deleteCollection(item);
            return false;
          }
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectionDetailScreen(
                  collection: item,
                  onMutated: _fetchCollections,
                ),
              ),
            );
            _fetchCollections();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Donor Name & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.water_drop, color: AppColors.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.dateRange.isNotEmpty ? 'Range: ${item.dateRange}' : 'Single Day Pickup',
                            style: const TextStyle(fontSize: 13, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(item.status),
                  ],
                ),
                const Divider(height: 24),

                // Metrics row: Collection Date & Total Volume
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.event_available, size: 16, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Date: ${item.formattedCollectionDate}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.opacity, size: 14, color: AppColors.primaryNavy),
                          const SizedBox(width: 4),
                          Text(
                            '${item.effectiveVolume.round()} ml',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: REFRIGERATORS TAB
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildRefrigeratorsTab() {
    final isArchived = _fridgesArchiveFilter == 1;
    final fridgesSource = isArchived ? _archivedFridges : _activeFridges;

    // Filter by search query
    final query = _fridgeSearchController.text.trim().toLowerCase();
    final fridges = query.isEmpty
        ? fridgesSource
        : fridgesSource.where((f) => f.name.toLowerCase().contains(query) || f.fridgeType.toLowerCase().contains(query)).toList();

    final allPasteurized = _activeFridges.where((f) => f.isPasteurized).toList();

    return Column(
      children: [
        // Controls: Active/Archived & Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Segmented Button
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Active Fridges'), icon: Icon(Icons.kitchen)),
                        ButtonSegment(value: 1, label: Text('Archived'), icon: Icon(Icons.archive_outlined)),
                      ],
                      selected: {_fridgesArchiveFilter},
                      onSelectionChanged: (set) {
                        setState(() => _fridgesArchiveFilter = set.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Bar
              TextField(
                controller: _fridgeSearchController,
                decoration: InputDecoration(
                  hintText: 'Search refrigerator name or type...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _fridgeSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _fridgeSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // List View with Pull-to-refresh
        Expanded(
          child: _isLoadingFridges
              ? const Center(child: CircularProgressIndicator())
              : _fridgesError != null
                  ? _buildErrorView(_fridgesError!, _fetchFridges)
                  : fridges.isEmpty
                      ? _buildEmptyView(
                          isArchived ? 'No archived refrigerators found.' : 'No refrigerators found.',
                          subtitle: isArchived
                              ? 'Archived refrigerators will appear here.'
                              : 'Tap "New Refrigerator" to set up an Unpasteurized or Pasteurized fridge.',
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchFridges,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 80, left: 16, right: 16),
                            itemCount: fridges.length,
                            itemBuilder: (context, index) {
                              final fridge = fridges[index];
                              return _buildFridgeCard(fridge, allPasteurized);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFridgeCard(FridgeModel fridge, List<FridgeModel> allPasteurized) {
    final isArchived = fridge.isDeleted || _fridgesArchiveFilter == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('fridge_${fridge.id}'),
        background: _buildSwipeBackground(
          color: isArchived ? AppColors.primaryBlue : AppColors.warning,
          icon: isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          alignment: Alignment.centerLeft,
          label: isArchived ? 'Restore' : 'Archive',
        ),
        secondaryBackground: _buildSwipeBackground(
          color: AppColors.error,
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
          label: 'Delete',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (isArchived) {
              await _restoreFridge(fridge);
            } else {
              await _archiveFridge(fridge);
            }
            return false;
          } else {
            await _deleteFridge(fridge);
            return false;
          }
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FridgeDetailScreen(
                  initialFridge: fridge,
                  allPasteurizedFridges: allPasteurized,
                  onMutated: _fetchFridges,
                ),
              ),
            );
            _fetchFridges();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Fridge Name & Type Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: fridge.isUnpasteurized ? AppColors.softBlue : const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.kitchen,
                        color: fridge.isUnpasteurized ? AppColors.primaryBlue : AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fridge.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fridge.fridgeType,
                            style: TextStyle(
                              fontSize: 13,
                              color: fridge.isUnpasteurized ? AppColors.primaryBlue : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total Volume Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${fridge.totalVolume} ml',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metrics / Status Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Entry count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.format_list_bulleted, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Text(
                            '${fridge.entryCount} entries',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy),
                          ),
                        ],
                      ),
                    ),

                    // Near-expiry count (> 0)
                    if (fridge.nearExpiryCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              '${fridge.nearExpiryCount} near expiry (<7d)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Expired count (> 0)
                    if (fridge.expiredCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              '${fridge.expiredCount} expired',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeft) Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (!isLeft) const SizedBox(width: 8),
          if (!isLeft) Icon(icon, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'collected':
      case 'completed':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'stored':
        bg = AppColors.softBlue;
        fg = AppColors.primaryNavy;
        break;
      case 'dispensed':
        bg = AppColors.primaryBlue.withValues(alpha: 0.15);
        fg = AppColors.primaryBlue;
        break;
      case 'pending':
      default:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Unable to load data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String title, {String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.primaryBlue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

