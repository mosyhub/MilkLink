import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/article_model.dart';
import '../../providers/articles_provider.dart';
import '../../widgets/app_widgets.dart';
import '../content/announcement_detail_screen.dart';
import 'article_detail_screen.dart';

class _UnifiedContentItem {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String? category;
  final String type; // 'Article' or 'Announcement'
  final DateTime createdAt;
  final dynamic original;

  _UnifiedContentItem({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    this.category,
    required this.type,
    required this.createdAt,
    required this.original,
  });
}

class ArticlesScreen extends StatefulWidget {
  final String initialFilter;

  const ArticlesScreen({super.key, this.initialFilter = 'All'});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late String _selectedFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ArticlesProvider>(context, listen: false).fetchAll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articlesProvider = Provider.of<ArticlesProvider>(context);

    // Merge articles and announcements into one unified list
    final List<_UnifiedContentItem> allItems = [];

    for (final a in articlesProvider.articles) {
      allItems.add(_UnifiedContentItem(
        id: a.id,
        title: a.title,
        summary: a.content.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        imageUrl: a.firstImageUrl,
        category: 'Health',
        type: 'Article',
        createdAt: a.createdAt,
        original: a,
      ));
    }

    for (final ann in articlesProvider.announcements) {
      allItems.add(_UnifiedContentItem(
        id: ann.id,
        title: ann.title,
        summary: ann.description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
        imageUrl: ann.firstImageUrl,
        category: ann.tags.isNotEmpty ? ann.tags.first : 'Notice',
        type: 'Announcement',
        createdAt: ann.createdAt,
        original: ann,
      ));
    }

    // Sort newest first
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Filter
    final filtered = allItems.where((item) {
      if (_selectedFilter == 'Articles' && item.type != 'Article') return false;
      if (_selectedFilter == 'Announcements' && item.type != 'Announcement') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchSummary = item.summary.toLowerCase().contains(q);
        final matchTag = item.category?.toLowerCase().contains(q) ?? false;
        if (!matchTitle && !matchSummary && !matchTag) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppTopBar(),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => articlesProvider.fetchAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Text(
                'Articles & Announcements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              TextFormField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search articles & announcements...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              FilterChips(
                options: const ['All', 'Articles', 'Announcements'],
                selected: _selectedFilter,
                onSelected: (val) => setState(() => _selectedFilter = val),
              ),
              const SizedBox(height: 16),

              // List
              if (articlesProvider.status == ArticlesStatus.loading && allItems.isEmpty)
                ...List.generate(3, (i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LoadingSkeleton(height: 100, radius: 20),
                    ))
              else if (filtered.isEmpty)
                const EmptyState(message: 'Nothing here yet')
              else
                ...filtered.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildContentCard(context, item, articlesProvider),
                    )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    _UnifiedContentItem item,
    ArticlesProvider articlesProvider,
  ) {
    final dateStr = DateFormat('MMM d, yyyy').format(item.createdAt);
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        if (item.type == 'Announcement' && item.original is AnnouncementModel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnnouncementDetailScreen(
                announcement: item.original as AnnouncementModel,
                isAdmin: false,
                onMutated: () => articlesProvider.fetchAll(),
              ),
            ),
          );
        } else if (item.original is ArticleModel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: item.original as ArticleModel),
            ),
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type & Category tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.type == 'Announcement'
                            ? AppColors.softBlue
                            : AppColors.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.type == 'Announcement'
                              ? AppColors.primaryBlue
                              : AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    if (item.category != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.category!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),

                // One-line summary
                Text(
                  item.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasImage) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
