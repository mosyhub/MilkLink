import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/admin/admin_models.dart';

class AdminSummaryCard extends StatelessWidget {
  const AdminSummaryCard({
    super.key,
    required this.module,
    required this.records,
    required this.metrics,
  });

  final AdminModule module;
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    final description = switch (module) {
      AdminModule.donors =>
        'Search donors by barangay and type, review child details, donation logs, interview forms, and laboratory eligibility records.',
      AdminModule.recipients =>
        'Manage baby and mother profiles, patient metrics, admission timestamps, and recipient records.',
      AdminModule.schedules =>
        'Track upcoming, ongoing, and completed events alongside pickup status history.',
      AdminModule.inventory =>
        'Monitor fridges, pasteurization batches, volume, QR identifiers, expiration dates, and collections.',
      AdminModule.accounts =>
        'Search and manage employee identities, contacts, emails, and Admin or Staff roles.',
      AdminModule.content =>
        'Manage announcements and articles with descriptions and image upload placeholders.',
      AdminModule.metrics =>
        'Review collected and dispensed volume, barangay distribution, donor ages, and hospital trends.',
      AdminModule.requests =>
        'Process recipient orders with prescribed volume, days, physician parameters, and status tracking.',
    };

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${records.length} records available',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: AppColors.textSecondary)),
            if (module == AdminModule.metrics && metrics.isNotEmpty) ...[
              const Divider(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metrics.entries.take(6).map((entry) {
                  return Chip(label: Text('${entry.key}: ${entry.value}'));
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
