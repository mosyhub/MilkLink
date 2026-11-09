import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/article_model.dart';
import 'announcement_form_screen.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool isAdmin;
  final VoidCallback onMutated;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
    required this.isAdmin,
    required this.onMutated,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late AnnouncementModel _announcement;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await ApiClient.get(ApiConstants.announcementById(_announcement.id));
      if (res['success'] == true && res['article'] != null) {
        if (mounted) {
          setState(() {
            _announcement = AnnouncementModel.fromJson(res['article']);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Announcement'),
        content: Text('Archive "${_announcement.title}"?\n\nIt will be hidden from staff and patients.'),
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

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.announcementArchive(_announcement.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement archived'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Announcement'),
        content: Text('Restore "${_announcement.title}" to active?'),
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

    setState(() => _isLoading = true);
    try {
      await ApiClient.put(ApiConstants.announcementRestore(_announcement.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement restored'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Announcement'),
        content: Text(
          'Permanently delete "${_announcement.title}"?\n\nThis action cannot be undone and will delete all stored images.',
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
      await ApiClient.delete(ApiConstants.announcementById(_announcement.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement permanently deleted'), backgroundColor: AppColors.success),
      );
      widget.onMutated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementFormScreen(announcement: _announcement),
      ),
    );
    if (updated == true) {
      widget.onMutated();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Details'),
        actions: [
          if (widget.isAdmin)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _edit();
                if (val == 'archive') _archive();
                if (val == 'restore') _restore();
                if (val == 'delete') _delete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Announcement')),
                if (!_announcement.isDeleted)
                  const PopupMenuItem(value: 'archive', child: Text('Archive'))
                else ...[
                  const PopupMenuItem(value: 'restore', child: Text('Restore')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Permanently', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status & Tags row
                  Row(
                    children: [
                      if (widget.isAdmin && !_announcement.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Inactive', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      if (widget.isAdmin && _announcement.isDeleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Archived', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      Text(
                        _announcement.formattedCreatedAt,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _announcement.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 12),

                  // Author info
                  if (_announcement.authorName != null && _announcement.authorName!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Posted by ${_announcement.authorName}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (_announcement.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _announcement.tags.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('#$t', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Image gallery
                  if (_announcement.images.isNotEmpty) ...[
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        itemCount: _announcement.images.length,
                        itemBuilder: (ctx, i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(_announcement.images[i].url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_announcement.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            'Swipe to view ${_announcement.images.length} photos',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Description Body
                  const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  Text(
                    _announcement.description,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
    );
  }
}

