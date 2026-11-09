import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/dashboard_metrics_model.dart';
import '../requests/milk_requests_screen.dart';

class MetricsDashboardScreen extends StatefulWidget {
  const MetricsDashboardScreen({super.key});

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  String _dateFilter = '30 days'; // Today | 7 days | 30 days | This year | Custom range
  DateTimeRange? _customRange;
  double _lowStockThreshold = 1000;

  DashboardMetricsResponse? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  void _calculateDateRange(String filter, out) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = now;

    switch (filter) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case '7 days':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30 days':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'This year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'Custom range':
        if (_customRange != null) {
          start = _customRange!.start;
          end = _customRange!.end;
        }
        break;
    }

    out['start'] = start;
    out['end'] = end;
  }

  Future<void> _fetchMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final range = <String, DateTime?>{};
      _calculateDateRange(_dateFilter, range);

      final queryParams = <String, String>{
        'lowStockThreshold': _lowStockThreshold.toString(),
        if (range['start'] != null) 'startDate': range['start']!.toIso8601String(),
        if (range['end'] != null) 'endDate': range['end']!.toIso8601String(),
      };

      final uri = Uri.parse(ApiConstants.dashboardMetrics).replace(queryParameters: queryParams);
      final res = await ApiClient.get(uri.toString());

      if (res is Map) {
        setState(() {
          _data = DashboardMetricsResponse.fromJson(Map<String, dynamic>.from(res));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to load metrics dashboard. Tap to retry.';
        _isLoading = false;
      });
    }
  }

  void _onStatusCardTapped(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MilkRequestsScreen(initialStatus: status),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 14)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _dateFilter = 'Custom range';
      });
      _fetchMetrics();
    }
  }

  void _showSettingsDialog() {
    final thresholdCtrl = TextEditingController(text: _lowStockThreshold.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Metrics Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set low stock alert threshold for pasteurized milk:'),
            const SizedBox(height: 12),
            TextField(
              controller: thresholdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Threshold (mL)',
                border: OutlineInputBorder(),
                suffixText: 'mL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () {
              final val = double.tryParse(thresholdCtrl.text);
              if (val != null && val > 0) {
                setState(() => _lowStockThreshold = val);
                Navigator.pop(ctx);
                _fetchMetrics();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Threshold Settings',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _fetchMetrics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDateFilterRow(),
                      const SizedBox(height: 16),
                      if (_data != null) ...[
                        _buildAlertsPanel(_data!.alerts),
                        const SizedBox(height: 16),
                        _buildSummarySection(_data!.summary),
                        const SizedBox(height: 20),
                        _buildChartsSection(_data!),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Last updated: ${DateFormat('MMM dd, yyyy hh:mm a').format(_data!.lastUpdated)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Today', '7 days', '30 days', 'This year', 'Custom range'].map((f) {
          final isSelected = _dateFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f == 'Custom range' && _customRange != null
                    ? '${DateFormat('MM/dd').format(_customRange!.start)} - ${DateFormat('MM/dd').format(_customRange!.end)}'
                    : f,
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  if (f == 'Custom range') {
                    _pickCustomRange();
                  } else {
                    setState(() => _dateFilter = f);
                    _fetchMetrics();
                  }
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlertsPanel(MetricsAlerts alerts) {
    final hasAlerts = alerts.lowStock ||
        alerts.expiringBatches.isNotEmpty ||
        alerts.pendingOlderThan24h > 0 ||
        alerts.requestsExceedingStock > 0;

    if (!hasAlerts) {
      return Card(
        elevation: 0,
        color: AppColors.success.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 10),
              Text('All stock and pending requests are within healthy thresholds.', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Active Inventory & Request Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown)),
              ],
            ),
            const Divider(height: 20),
            if (alerts.lowStock)
              _alertTile(
                Icons.battery_alert,
                'Low Pasteurized Stock: ${NumberFormat('#,##0').format(alerts.currentPasteurizedStock)} mL left (Below ${NumberFormat('#,##0').format(alerts.threshold)} mL threshold).',
                Colors.red,
              ),
            if (alerts.pendingOlderThan24h > 0)
              _alertTile(
                Icons.hourglass_bottom,
                '${alerts.pendingOlderThan24h} pending request(s) older than 24 hours requiring review.',
                Colors.orange,
                onTap: () => _onStatusCardTapped('Pending'),
              ),
            if (alerts.requestsExceedingStock > 0)
              _alertTile(
                Icons.trending_up,
                '${alerts.requestsExceedingStock} request(s) exceed current pasteurized stock capacity.',
                Colors.deepOrange,
              ),
            if (alerts.expiringBatches.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${alerts.expiringBatches.length} batch(es) near expiration (<= 7 days):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
              ),
              const SizedBox(height: 4),
              ...alerts.expiringBatches.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      Icon(b.isExpired ? Icons.cancel : Icons.alarm, size: 16, color: b.isExpired ? Colors.red : Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Batch #${b.batchNumber}: ${b.bottlesAvailable} bottle(s) â€¢ Exp: ${DateFormat('MMM dd').format(b.expirationDate)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: b.isExpired ? Colors.red : Colors.brown),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _alertTile(IconData icon, String text, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(SummaryMetrics s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Operational Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _metricCard('Milk Collected', '${NumberFormat('#,##0').format(s.totalMilkCollected)} mL', Icons.water_drop, AppColors.primaryBlue),
            _metricCard('Milk Pasteurized', '${NumberFormat('#,##0').format(s.totalMilkPasteurized)} mL', Icons.science, AppColors.softPink),
            _metricCard('Milk Dispensed', '${NumberFormat('#,##0').format(s.totalMilkDispensed)} mL', Icons.local_hospital, AppColors.success),
            _metricCard('Volume Requested', '${NumberFormat('#,##0').format(s.totalVolumeRequested)} mL', Icons.assignment, Colors.purple),
            _metricCard('Pasteurized Stock', '${NumberFormat('#,##0').format(s.pasteurizedStock)} mL\n(${s.pasteurizedBottles} bottles)', Icons.kitchen, AppColors.primaryNavy),
            _metricCard('Unpasteurized Stock', '${NumberFormat('#,##0').format(s.unpasteurizedStock)} mL', Icons.inventory, Colors.teal),
            _metricCard('Pending Requests', '${s.currentPendingRequests}', Icons.hourglass_empty, Colors.orange, onTap: () => _onStatusCardTapped('Pending')),
            _metricCard('Under Review', '${s.currentUnderReviewRequests}', Icons.rate_review, Colors.indigo, onTap: () => _onStatusCardTapped('Under Review')),
            _metricCard('Fulfillment Rate', '${s.fulfillmentRate}%', Icons.done_all, AppColors.success),
            _metricCard('Avg Fulfillment Time', '${s.avgTimeToFulfillHours} hrs', Icons.timer, Colors.blueGrey),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(DashboardMetricsResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics & Visual Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        // Requests by status bar/donut chart
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Requests by Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: data.requestsByStatus.entries.map((e) {
                        final val = e.value.toDouble();
                        Color c;
                        switch (e.key) {
                          case 'Pending': c = Colors.orange; break;
                          case 'Under Review': c = AppColors.primaryBlue; break;
                          case 'Approved': c = AppColors.success; break;
                          case 'Fulfilled': c = AppColors.primaryNavy; break;
                          case 'Rejected': c = AppColors.error; break;
                          case 'Cancelled': c = Colors.grey; break;
                          default: c = Colors.blueGrey;
                        }
                        return PieChartSectionData(
                          value: val > 0 ? val : 0.001,
                          title: val > 0 ? '${e.key}\n${val.toInt()}' : '',
                          color: c,
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pasteurized stock by bottle type
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Pasteurized Bottles by Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                if (data.pasteurizedByBottleType.isEmpty)
                  const Text('No pasteurized stock records found.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                else
                  ...data.pasteurizedByBottleType.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 10, color: AppColors.primaryNavy),
                          const SizedBox(width: 8),
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${e.value} bottles', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Top donors
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Donors by Volume (Ranked)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(height: 20),
                if (data.topDonors.isEmpty)
                  const Text('No collection records in selected date range.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                else
                  ...data.topDonors.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final donor = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                        child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy)),
                      ),
                      title: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Text(
                        '${NumberFormat('#,##0').format(donor.volume)} mL',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error ?? 'An error occurred', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: _fetchMetrics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

