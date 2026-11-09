import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/article_model.dart';
import '../../providers/auth_provider.dart';
import 'announcement_detail_screen.dart';
import 'announcement_form_screen.dart';
import 'article_detail_screen.dart';
import 'article_form_screen.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Announcements state
  List<AnnouncementModel> _announcements = [];
  bool _announcementsLoading = true;
  String? _announcementsError;
  String _announcementStatus = 'Active'; // Active | Archived | All
  String? _selectedTag;
  final TextEditingController _announcementSearch = TextEditingController();

  // Articles state
  List<ArticleModel> _articles = [];
  bool _articlesLoading = true;
  String? _articlesError;
  String _articleStatus = 'Active'; // Active | Archived | All
  final TextEditingController _articleSearch = TextEditingController();

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _isAdmin = auth.isAdmin;
      _fetchAnnouncements();
      _fetchArticles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _announcementSearch.dispose();
    _articleSearch.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _announcementsLoading = true;
      _announcementsError = null;
    });

    try {
      final queryParams = <String, String>{
        'limit': '100',
        if (_isAdmin) 'status': _announcementStatus,
        if (_announcementSearch.text.trim().isNotEmpty)
          'search': _announcementSearch.text.trim(),
        if (_selectedTag != null && _selectedTag!.isNotEmpty)
          'tag': _selectedTag!,
      };

      final uri = Uri.parse(ApiConstants.announcements).replace(queryParameters: queryParams);
      final res = await ApiClient.get(uri.toString());

      final List<AnnouncementModel> parsed = [];
      if (res is Map && res['articles'] is List) {
        for (final item in res['articles']) {
          if (item is Map) {
            parsed.add(AnnouncementModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (mounted) {
        setState(() {
          _announcements = parsed;
          _announcementsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _announcementsError = 'Unable to load announcements. Tap to retry.';
          _announcementsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _articlesLoading = true;
      _articlesError = null;
    });

    try {
      final queryParams = <String, String>{
        'limit': '100',
        if (_isAdmin) 'status': _articleStatus,
        if (_articleSearch.text.trim().isNotEmpty)
          'search': _articleSearch.text.trim(),
      };

      final uri = Uri.parse(ApiConstants.articles).replace(queryParameters: queryParams);
      final res = await ApiClient.get(uri.toString());

      final List<ArticleModel> parsed = [];
      if (res is Map && res['articles'] is List) {
        for (final item in res['articles']) {
          if (item is Map) {
            parsed.add(ArticleModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (mounted) {
        setState(() {
          _articles = parsed;
          _articlesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _articlesError = 'Unable to load articles. Tap to retry.';
          _articlesLoading = false;
        });
      }
    }
  }

  Future<void> _archiveAnnouncement(AnnouncementModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Announcement'),
        content: Text('Archive "${a.title}"?'),
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
      await ApiClient.put(ApiConstants.announcementArchive(a.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement archived'), backgroundColor: AppColors.success),
      );
      _fetchAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _restoreAnnouncement(AnnouncementModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Announcement'),
        content: Text('Restore "${a.title}" to active?'),
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
      await ApiClient.put(ApiConstants.announcementRestore(a.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement restored'), backgroundColor: AppColors.success),
      );
      _fetchAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text('Permanently delete "${a.title}"?\n\nThis cannot be undone.'),
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
      await ApiClient.delete(ApiConstants.announcementById(a.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement permanently deleted'), backgroundColor: AppColors.success),
      );
      _fetchAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _archiveArticle(ArticleModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Article'),
        content: Text('Archive "${a.title}"?'),
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
      await ApiClient.put(ApiConstants.articleArchive(a.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article archived'), backgroundColor: AppColors.success),
      );
      _fetchArticles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _restoreArticle(ArticleModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Article'),
        content: Text('Restore "${a.title}" to active?'),
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
      await ApiClient.put(ApiConstants.articleRestore(a.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article restored'), backgroundColor: AppColors.success),
      );
      _fetchArticles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteArticle(ArticleModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text('Permanently delete "${a.title}"?\n\nThis cannot be undone.'),
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
      await ApiClient.delete(ApiConstants.articleById(a.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article permanently deleted'), backgroundColor: AppColors.success),
      );
      _fetchArticles();
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
        title: const Text('Content Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          indicatorColor: AppColors.primaryNavy,
          tabs: const [
            Tab(text: 'Announcements', icon: Icon(Icons.campaign_outlined)),
            Tab(text: 'Articles', icon: Icon(Icons.article_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncementsTab(),
          _buildArticlesTab(),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              onPressed: () async {
                if (_tabController.index == 0) {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementFormScreen()),
                  );
                  if (created == true) _fetchAnnouncements();
                } else {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const ArticleFormScreen()),
                  );
                  if (created == true) _fetchArticles();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAnnouncementsTab() {
    return Column(
      children: [
        // Search & Filter header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _announcementSearch,
                decoration: InputDecoration(
                  hintText: 'Search announcements...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _announcementSearch.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _announcementSearch.clear();
                            _fetchAnnouncements();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onSubmitted: (_) => _fetchAnnouncements(),
              ),
              if (_selectedTag != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Filtering by tag: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Chip(
                      label: Text('#$_selectedTag'),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _selectedTag = null);
                        _fetchAnnouncements();
                      },
                      backgroundColor: AppColors.softBlue.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
              if (_isAdmin) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Active', label: Text('Active')),
                          ButtonSegment(value: 'Archived', label: Text('Archived')),
                          ButtonSegment(value: 'All', label: Text('All')),
                        ],
                        selected: {_announcementStatus},
                        onSelectionChanged: (v) {
                          setState(() => _announcementStatus = v.first);
                          _fetchAnnouncements();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // List View
        Expanded(
          child: _announcementsLoading
              ? const Center(child: CircularProgressIndicator())
              : _announcementsError != null
                  ? _buildErrorWidget(_announcementsError!, _fetchAnnouncements)
                  : _announcements.isEmpty
                      ? const Center(
                          child: Text('No announcements yet', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAnnouncements,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _announcements.length,
                            itemBuilder: (ctx, i) {
                              final item = _announcements[i];
                              return _buildAnnouncementCard(item);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel a) {
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
              builder: (_) => AnnouncementDetailScreen(
                announcement: a,
                isAdmin: _isAdmin,
                onMutated: _fetchAnnouncements,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.softBlue.withValues(alpha: 0.3),
                  child: a.firstImageUrl != null
                      ? Image.network(
                          a.firstImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.campaign, color: AppColors.primaryNavy),
                        )
                      : const Icon(Icons.campaign, color: AppColors.primaryNavy, size: 36),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isAdmin && !a.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Inactive', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (_isAdmin && a.isDeleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Archived', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        Expanded(
                          child: Text(
                            a.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Tags & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (a.tags.isNotEmpty)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: a.tags.map((t) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedTag = t);
                                      _fetchAnnouncements();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.softBlue.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('#$t', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        else
                          const SizedBox(),
                        Text(a.formattedCreatedAt, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_isAdmin) return cardContent;

    return Dismissible(
      key: Key(a.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          if (!a.isDeleted) {
            await _archiveAnnouncement(a);
          } else {
            await _restoreAnnouncement(a);
          }
        } else {
          await _deleteAnnouncement(a);
        }
        return false;
      },
      background: Container(
        color: !a.isDeleted ? AppColors.warning : AppColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(!a.isDeleted ? Icons.archive : Icons.unarchive, color: Colors.white),
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

  Widget _buildArticlesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _articleSearch,
                decoration: InputDecoration(
                  hintText: 'Search articles...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _articleSearch.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _articleSearch.clear();
                            _fetchArticles();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onSubmitted: (_) => _fetchArticles(),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Active', label: Text('Active')),
                          ButtonSegment(value: 'Archived', label: Text('Archived')),
                          ButtonSegment(value: 'All', label: Text('All')),
                        ],
                        selected: {_articleStatus},
                        onSelectionChanged: (v) {
                          setState(() => _articleStatus = v.first);
                          _fetchArticles();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: _articlesLoading
              ? const Center(child: CircularProgressIndicator())
              : _articlesError != null
                  ? _buildErrorWidget(_articlesError!, _fetchArticles)
                  : _articles.isEmpty
                      ? const Center(
                          child: Text('No articles yet', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchArticles,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _articles.length,
                            itemBuilder: (ctx, i) {
                              final item = _articles[i];
                              return _buildArticleCard(item);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(ArticleModel a) {
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
              builder: (_) => ArticleDetailScreen(
                article: a,
                isAdmin: _isAdmin,
                onMutated: _fetchArticles,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.softBlue.withValues(alpha: 0.3),
                  child: a.firstImageUrl != null
                      ? Image.network(
                          a.firstImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.article_outlined, color: AppColors.primaryNavy),
                        )
                      : const Icon(Icons.article_outlined, color: AppColors.primaryNavy, size: 36),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isAdmin && a.isDeleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Archived', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        Expanded(
                          child: Text(
                            a.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(a.formattedCreatedAt, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_isAdmin) return cardContent;

    return Dismissible(
      key: Key(a.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          if (!a.isDeleted) {
            await _archiveArticle(a);
          } else {
            await _restoreArticle(a);
          }
        } else {
          await _deleteArticle(a);
        }
        return false;
      },
      background: Container(
        color: !a.isDeleted ? AppColors.warning : AppColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(!a.isDeleted ? Icons.archive : Icons.unarchive, color: Colors.white),
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

  Widget _buildErrorWidget(String msg, VoidCallback onRetry) {
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
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
