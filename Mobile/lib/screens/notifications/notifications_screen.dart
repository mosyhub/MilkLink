import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationsProvider>(context);
    final all = notifProvider.notifications;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayList = all.where((n) => n.notifiedAt.isAfter(todayStart)).toList();
    final earlierList = all.where((n) => !n.notifiedAt.isAfter(todayStart)).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => notifProvider.fetchNotifications(),
        child: all.isEmpty
            ? const Center(
                child: EmptyState(
                  message: 'No notifications yet.\nYou will receive reminders for appointments and milk processing updates.',
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (todayList.isNotEmpty) ...[
                      const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...todayList.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildNotifCard(context, n, notifProvider),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (earlierList.isNotEmpty) ...[
                      const Text(
                        'Earlier',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...earlierList.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildNotifCard(context, n, notifProvider),
                          )),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNotifCard(
    BuildContext context,
    NotificationItem notif,
    NotificationsProvider notifProvider,
  ) {
    final timeStr = DateFormat('MMM d, h:mm a').format(notif.notifiedAt);

    return AppCard(
      padding: const EdgeInsets.all(14),
      color: notif.seen ? Colors.white : AppColors.softBlue.withValues(alpha: 0.5),
      onTap: () {
        if (!notif.seen) {
          notifProvider.markAsSeen(notif.id);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: notif.seen ? FontWeight.w600 : FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    if (!notif.seen) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notif.body,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
