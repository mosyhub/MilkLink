import 'package:flutter/material.dart';

enum AdminModule {
  donors('Donor Records', Icons.favorite),
  recipients('Recipient Records', Icons.child_care),
  schedules('Schedules', Icons.calendar_month),
  inventory('Inventory', Icons.inventory_2_outlined),
  accounts('Account Management', Icons.manage_accounts),
  content('Content Management', Icons.library_books),
  metrics('Metrics', Icons.bar_chart),
  requests('Milk Requesting', Icons.assignment);

  const AdminModule(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AdminDashboardData {
  const AdminDashboardData({
    this.metrics = const {},
    this.inventory = const [],
    this.pickups = const [],
    this.schedules = const [],
    this.accounts = const [],
    this.articles = const [],
    this.announcements = const [],
  });

  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> inventory;
  final List<Map<String, dynamic>> pickups;
  final List<Map<String, dynamic>> schedules;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> articles;
  final List<Map<String, dynamic>> announcements;

  List<Map<String, dynamic>> recordsFor(AdminModule module) {
    switch (module) {
      case AdminModule.inventory:
        return inventory;
      case AdminModule.schedules:
        return schedules;
      case AdminModule.accounts:
        return accounts;
      case AdminModule.content:
        return [...announcements, ...articles];
      default:
        return const [];
    }
  }
}
