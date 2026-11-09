import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/milk_request_model.dart';
import 'request_detail_screen.dart';
import 'request_form_screen.dart';

class MilkRequestsScreen extends StatefulWidget {
  final String? initialStatus;

  const MilkRequestsScreen({super.key, this.initialStatus});

  @override
  State<MilkRequestsScreen> createState() => _MilkRequestsScreenState();
}

class _MilkRequestsScreenState extends State<MilkRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _tabs = [
    'Pending',
    'Under Review',
    'Approved',
    'Fulfilled',
    'Rejected',
    'Cancelled',
    'Archived',
  ];

  Map<String, int> _counts = {
    'Pending': 0,
    'Under Review': 0,
    'Approved': 0,
    'Fulfilled': 0,
    'Rejected': 0,
    'Cancelled': 0,
    'Archived': 0,
  };

  List<MilkRequestModel> _requests = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedRelationship = 'All';

  @override
  void initState() {
    super.initState();
    int initialIdx = 0;
    if (widget.initialStatus != null) {
      final idx = _tabs.indexOf(widget.initialStatus!);
      if (idx != -1) initialIdx = idx;
    }

    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIdx);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        _fetchRequests();
      }
    });

    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _currentStatus => _tabs[_tabController.index];

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, String>{
        'status': _currentStatus,
        'limit': '100',
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
        if (_selectedRelationship != 'All') 'relationship': _selectedRelationship,
      };

      final uri = Uri.parse(ApiConstants.requests).replace(queryParameters: queryParams);
      final res = await ApiClient.get(uri.toString());

      final List<MilkRequestModel> parsed = [];
      if (res is Map && res['requests'] is List) {
        for (final item in res['requests']) {
          if (item is Map) {
            parsed.add(MilkRequestModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (res is Map && res['counts'] is Map) {
        final Map<String, int> cMap = {};
        res['counts'].forEach((k, v) {
          cMap[k.toString()] = (v as num).toInt();
        });
        _counts = cMap;
      }

      if (mounted) {
        setState(() {
          _requests = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load milk requests. Tap to retry.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _archiveRequest(MilkRequestModel r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Request'),
        content: Text('Archive #${r.requestNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.put(ApiConstants.softDeleteRequest(r.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request archived'), backgroundColor: AppColors.success),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _restoreRequest(MilkRequestModel r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Request'),
        content: Text('Restore #${r.requestNumber} back to active?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.put(ApiConstants.restoreRequest(r.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request restored'), backgroundColor: AppColors.success),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteRequest(MilkRequestModel r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Request'),
        content: Text('Permanently delete #${r.requestNumber}?\n\nThis cannot be undone.'),
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

    try {
      await ApiClient.delete(ApiConstants.requestById(r.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request permanently deleted'), backgroundColor: AppColors.success),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryNavy,
          indicatorColor: AppColors.primaryNavy,
          tabs: _tabs.map((tab) {
            final c = _counts[tab] ?? 0;
            return Tab(
              child: Row(
                children: [
                  Text(tab),
                  if (c > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$c', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by recipient, requester, request #...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchRequests();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _fetchRequests(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Relationship: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedRelationship,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Relationships')),
                          DropdownMenuItem(value: 'Mother / Guardian', child: Text('Mother / Guardian')),
                          DropdownMenuItem(value: 'Father', child: Text('Father')),
                          DropdownMenuItem(value: 'Healthcare Provider', child: Text('Healthcare Provider')),
                          DropdownMenuItem(value: 'Relative / Foster', child: Text('Relative / Foster')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedRelationship = v);
                            _fetchRequests();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : _requests.isEmpty
                        ? Center(
                            child: Text(
                              'No ${_currentStatus.toLowerCase()} requests found.',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchRequests,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _requests.length,
                              itemBuilder: (ctx, i) {
                                final r = _requests[i];
                                return _buildCard(r);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const RequestFormScreen()),
          );
          if (res == true) _fetchRequests();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCard(MilkRequestModel r) {
    final cardContent = Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                request: r,
                onMutated: _fetchRequests,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.requestNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy)),
                  _statusBadge(r.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r.recipientName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Requester: ${r.requester?.name ?? "Donor Account"} â€¢ ${r.relationToRecipient}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 4),
                      Text(r.formattedVolumeRequested, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text('(${r.feedingDurationDays} days)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  Text(r.formattedDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: Key(r.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          if (!r.isDeleted) {
            await _archiveRequest(r);
          } else {
            await _restoreRequest(r);
          }
        } else {
          await _deleteRequest(r);
        }
        return false;
      },
      background: Container(
        color: !r.isDeleted ? AppColors.warning : AppColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(!r.isDeleted ? Icons.archive : Icons.unarchive, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: cardContent,
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pending': color = Colors.orange; break;
      case 'Under Review': color = AppColors.primaryBlue; break;
      case 'Approved': color = AppColors.success; break;
      case 'Fulfilled': color = AppColors.primaryNavy; break;
      case 'Rejected': color = AppColors.error; break;
      case 'Cancelled': color = Colors.grey; break;
      default: color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildErrorWidget(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: _fetchRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

