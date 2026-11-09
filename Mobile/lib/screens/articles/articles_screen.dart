import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/articles_provider.dart';
import '../../widgets/article_card.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final articlesProvider = Provider.of<ArticlesProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Resources & Guides'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryNavy,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.accentPink,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accentPink,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Educational Articles'),
              Tab(text: 'Announcements'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => articlesProvider.fetchAll(),
          child: TabBarView(
            children: [
              // Articles Tab
              articlesProvider.articles.isEmpty
                  ? const Center(
                      child: Text('No articles published yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: articlesProvider.articles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final article = articlesProvider.articles[index];
                        return ArticleCard(
                          article: article,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArticleDetailScreen(article: article),
                              ),
                            );
                          },
                        );
                      },
                    ),

              // Announcements Tab
              articlesProvider.announcements.isEmpty
                  ? const Center(
                      child: Text('No announcements at this time.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: articlesProvider.announcements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final ann = articlesProvider.announcements[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.softPink,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ANNOUNCEMENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentPink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                ann.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ann.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

