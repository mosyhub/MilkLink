import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/inventory_models.dart';
import 'entry_form_screen.dart';
import 'fridge_form_screen.dart';
import 'pasteurization_form_screen.dart';

class FridgeDetailScreen extends StatefulWidget {
  final FridgeModel initialFridge;
  final List<FridgeModel> allPasteurizedFridges;
  final VoidCallback? onMutated;

  const FridgeDetailScreen({
    super.key,
    required this.initialFridge,
    this.allPasteurizedFridges = const [],
    this.onMutated,
  });

  @override
  State<FridgeDetailScreen> createState() => _FridgeDetailScreenState();
}

class _FridgeDetailScreenState extends State<FridgeDetailScreen>
    with SingleTickerProviderStateMixin {
  late FridgeModel _fridge;
  late final TabController _tabController;

  List<FridgeEntryModel> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Multi-selection for pasteurization in Unpasteurized fridge
  final Set<String> _selectedEntryIds = {};

  @override
  void initState() {
    super.initState();
    _fridge = widget.initialFridge;
    _tabController = TabController(length: _fridge.isUnpasteurized ? 3 : 2, vsync: this);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.get(ApiConstants.fridgeById(_fridge.id)),
        ApiClient.get(ApiConstants.fridgeEntries(_fridge.id)),
      ]);

      if (responses[0] is Map && responses[0]['fridge'] is Map) {
        _fridge = FridgeModel.fromJson(Map<String, dynamic>.from(responses[0]['fridge']));
      }

      final list = <FridgeEntryModel>[];
      if (responses[1] is Map && responses[1]['entries'] is List) {
        for (final m in responses[1]['entries']) {
          if (m is Map) list.add(FridgeEntryModel.fromJson(Map<String, dynamic>.from(m)));
        }
      }

      if (mounted) {
        setState(() {
          _entries = _fridge.isUnpasteurized
              ? list.where((e) => !e.isPasteurized && e.status != 'Pasteurized' && e.volume > 0).toList()
              : list;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _errorMessage = e.message; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _errorMessage = 'Failed to load entries.'; _isLoading = false; });
    }
  }

  int get _selectedPooledVolume {
    return _entries
        .where((e) => _selectedEntryIds.contains(e.id))
        .fold(0, (sum, e) => sum + e.volume);
  }

  void _toggleSelectEntry(String id) {
    setState(() {
      if (_selectedEntryIds.contains(id)) {
        _selectedEntryIds.remove(id);
      } else {
        _selectedEntryIds.add(id);
      }
    });
  }

  Future<void> _editFridge() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FridgeFormScreen(fridge: _fridge)),
    );
    if (updated == true) {
      widget.onMutated?.call();
      await _loadEntries();
      _showSnackbar('Refrigerator updated.');
    }
  }

  Future<void> _archiveFridge() async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Refrigerator',
      content: 'Archive "${_fridge.name}"? Entries inside will remain stored.',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteFridge(_fridge.id));
      widget.onMutated?.call();
      _showSnackbar('Refrigerator archived.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    }
  }

  Future<void> _restoreFridge() async {
    try {
      await ApiClient.put(ApiConstants.restoreFridge(_fridge.id));
      widget.onMutated?.call();
      _showSnackbar('Refrigerator restored.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    }
  }

  Future<void> _deleteFridge() async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Refrigerator',
      content: 'Permanently delete "${_fridge.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.fridgeById(_fridge.id));
      widget.onMutated?.call();
      _showSnackbar('Refrigerator deleted permanently.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    }
  }

  Future<void> _openPasteurization() async {
    final selected = _entries.where((e) => _selectedEntryIds.contains(e.id)).toList();
    if (selected.isEmpty) {
      _showSnackbar('Select at least one unpasteurized entry.', isError: true);
      return;
    }

    final pasteurizedFridges = widget.allPasteurizedFridges.isNotEmpty
        ? widget.allPasteurizedFridges
        : [_fridge];

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PasteurizationFormScreen(
          sourceFridge: _fridge,
          selectedEntries: selected,
          pasteurizedFridges: pasteurizedFridges,
        ),
      ),
    );

    if (created == true) {
      setState(() => _selectedEntryIds.clear());
      widget.onMutated?.call();
      await _loadEntries();
      _showSnackbar('Pasteurization complete. Batch stored in Pasteurized fridge.');
    }
  }

  Future<void> _editEntry(FridgeEntryModel entry) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(entry: entry, fridgeType: _fridge.fridgeType),
      ),
    );
    if (updated == true) {
      widget.onMutated?.call();
      await _loadEntries();
      _showSnackbar('Entry updated.');
    }
  }

  Future<void> _archiveEntry(FridgeEntryModel entry) async {
    final confirm = await _showConfirmDialog(
      title: 'Archive Entry',
      content: 'Archive entry for "${entry.displayDonorName}"?',
      confirmLabel: 'Archive',
      confirmColor: AppColors.warning,
    );
    if (!confirm) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteInventory(entry.id));
      widget.onMutated?.call();
      await _loadEntries();
      _showSnackbar('Entry archived.');
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    }
  }

  Future<void> _restoreEntry(FridgeEntryModel entry) async {
    try {
      await ApiClient.put(ApiConstants.restoreInventory(entry.id));
      widget.onMutated?.call();
      await _loadEntries();
      _showSnackbar('Entry restored.');
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    }
  }

  Future<void> _deleteEntry(FridgeEntryModel entry) async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Entry',
      content: 'Permanently delete entry for "${entry.displayDonorName}"? Volume will be removed.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await ApiClient.delete(ApiConstants.inventoryById(entry.id));
      widget.onMutated?.call();
      await _loadEntries();
      _showSnackbar('Entry permanently deleted.');
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnpast = _fridge.isUnpasteurized;

    // Filter categories
    final activeEntries = _entries
        .where((e) => !e.isExpired && e.status != 'Depleted' && !e.isPasteurized && e.volume > 0)
        .toList();
    final expiredEntries = _entries.where((e) => e.isExpired).toList();
    final depletedEntries = _entries.where((e) => e.status == 'Depleted').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_fridge.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(tooltip: 'Edit Fridge', icon: const Icon(Icons.edit_outlined), onPressed: _editFridge),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'archive') _archiveFridge();
              if (val == 'restore') _restoreFridge();
              if (val == 'delete') _deleteFridge();
            },
            itemBuilder: (_) => [
              if (!_fridge.isDeleted)
                const PopupMenuItem(value: 'archive', child: Text('Archive Refrigerator')),
              if (_fridge.isDeleted)
                const PopupMenuItem(value: 'restore', child: Text('Restore Refrigerator')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Refrigerator', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryNavy,
          tabs: isUnpast
              ? [
                  Tab(text: 'Active (${activeEntries.length})'),
                  Tab(text: 'Expired (${expiredEntries.length})'),
                  Tab(text: 'All (${_entries.length})'),
                ]
              : [
                  Tab(text: 'Active Batches (${activeEntries.length})'),
                  Tab(text: 'Depleted (${depletedEntries.length})'),
                ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    // Fridge metrics header card
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _metricBox(
                              label: 'Total Volume',
                              value: '${_fridge.totalVolume} ml',
                              icon: Icons.water_drop,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _metricBox(
                              label: 'Entries',
                              value: '${_fridge.entryCount}',
                              icon: Icons.list_alt,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _metricBox(
                              label: 'Near Expiry',
                              value: '${_fridge.nearExpiryCount}',
                              icon: Icons.warning_amber_rounded,
                              color: _fridge.nearExpiryCount > 0 ? AppColors.warning : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.border),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: isUnpast
                            ? [
                                _buildEntriesList(activeEntries, canPasteurize: true),
                                _buildEntriesList(expiredEntries, isExpiredSection: true),
                                _buildEntriesList(_entries),
                              ]
                            : [
                                _buildBatchesList(activeEntries),
                                _buildBatchesList(depletedEntries),
                              ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: isUnpast && _selectedEntryIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_selectedEntryIds.length} entries selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Pooled: $_selectedPooledVolume ml', style: const TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy, minimumSize: const Size(140, 48)),
                      icon: const Icon(Icons.science_outlined),
                      label: Text('Pasteurize ($_selectedPooledVolume ml)'),
                      onPressed: _openPasteurization,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _metricBox({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<FridgeEntryModel> list, {bool canPasteurize = false, bool isExpiredSection = false}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isExpiredSection ? Icons.check_circle_outline : Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                isExpiredSection ? 'No expired milk entries.' : 'No entries yet in this category.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedEntryIds.contains(item.id);

        Color expColor = AppColors.textSecondary;
        if (item.isExpired) expColor = AppColors.error;
        else if (item.isNearExpiry) expColor = AppColors.warning;

        return Dismissible(
          key: Key('entry_${item.id}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.endToStart) {
              _deleteEntry(item);
            } else {
              if (!item.isDeleted) _archiveEntry(item);
              else _restoreEntry(item);
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: !item.isDeleted ? AppColors.warning : AppColors.success, borderRadius: BorderRadius.circular(10)),
            child: Icon(!item.isDeleted ? Icons.archive : Icons.unarchive, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryNavy
                    : (item.isExpired ? AppColors.error.withOpacity(0.5) : AppColors.border),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (canPasteurize && !item.isExpired) {
                  _toggleSelectEntry(item.id);
                } else {
                  _editEntry(item);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (canPasteurize && !item.isExpired)
                      Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primaryNavy,
                        onChanged: (_) => _toggleSelectEntry(item.id),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.displayDonorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${item.volume} ml', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.event_outlined, size: 14, color: expColor),
                              const SizedBox(width: 4),
                              Text('Expires: ${item.formattedExpiration}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: expColor)),
                              const SizedBox(width: 8),
                              if (item.isExpired)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('EXPIRED (Disposal)', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                                )
                              else if (item.isNearExpiry)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(4)),
                                  child: Text('${item.daysUntilExpiration}d left', style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _editEntry(item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBatchesList(List<FridgeEntryModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No batches found.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final batch = list[index];
        final isDepleted = batch.status == 'Depleted' || batch.availableBottles == 0;

        Color expColor = AppColors.textSecondary;
        if (batch.isExpired) expColor = AppColors.error;
        else if (batch.isNearExpiry) expColor = AppColors.warning;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Batch #${batch.batchNumber ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDepleted ? AppColors.border : AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDepleted ? 'Depleted' : 'Active Batch',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDepleted ? AppColors.textMuted : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Pool #${batch.poolNumber ?? "N/A"} • ${batch.bottleType ?? 100} ml per bottle', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${batch.availableBottles} bottles available', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy, fontSize: 14)),
                    Text('${batch.volume} ml total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16, color: AppColors.border),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: expColor),
                    const SizedBox(width: 4),
                    Text('Expires: ${batch.formattedExpiration}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: expColor)),
                    if (batch.isExpired) ...[
                      const SizedBox(width: 8),
                      const Text('(EXPIRED - Do not dispense)', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                if (batch.donorNames.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Donors: ${batch.donorNames.join(", ")}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

