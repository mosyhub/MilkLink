import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/article_model.dart';
import 'article_form_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;
  final bool isAdmin;
  final VoidCallback onMutated;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.isAdmin,
    required this.onMutated,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late ArticleModel _article;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await ApiClient.get(ApiConstants.articleById(_article.id));
      if (res['success'] == true && res['article'] != null) {
        if (mounted) {
          setState(() {
            _article = ArticleModel.fromJson(res['article']);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Article'),
        content: Text('Archive "${_article.title}"?\n\nIt will be hidden from staff and patients.'),
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
      await ApiClient.put(ApiConstants.articleArchive(_article.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article archived'), backgroundColor: AppColors.success),
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
        title: const Text('Restore Article'),
        content: Text('Restore "${_article.title}" to active?'),
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
      await ApiClient.put(ApiConstants.articleRestore(_article.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article restored'), backgroundColor: AppColors.success),
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
        title: const Text('Permanently Delete Article'),
        content: Text(
          'Permanently delete "${_article.title}"?\n\nThis action cannot be undone and will delete all stored images.',
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
      await ApiClient.delete(ApiConstants.articleById(_article.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article permanently deleted'), backgroundColor: AppColors.success),
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
        builder: (_) => ArticleFormScreen(article: _article),
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
        title: const Text('Article Details'),
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
                const PopupMenuItem(value: 'edit', child: Text('Edit Article')),
                if (!_article.isDeleted)
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
                  // Status badge row
                  Row(
                    children: [
                      if (widget.isAdmin && _article.isDeleted)
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
                        _article.formattedCreatedAt,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _article.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    _article.description,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Image gallery
                  if (_article.images.isNotEmpty) ...[
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        itemCount: _article.images.length,
                        itemBuilder: (ctx, i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(_article.images[i].url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_article.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            'Swipe to view ${_article.images.length} photos',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Article Content Body with preserved paragraphs
                  const Text('Article Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  Text(
                    _article.content,
                    style: const TextStyle(fontSize: 15, height: 1.7),
                  ),
                ],
              ),
            ),
    );
  }
}

