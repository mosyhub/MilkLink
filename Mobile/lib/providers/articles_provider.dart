import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/article_model.dart';

enum ArticlesStatus { initial, loading, loaded, error }

class ArticlesProvider extends ChangeNotifier {
  ArticlesStatus _status = ArticlesStatus.initial;
  List<ArticleModel> _articles = [];
  List<AnnouncementModel> _announcements = [];
  String? _errorMessage;

  ArticlesStatus get status => _status;
  List<ArticleModel> get articles => _articles;
  List<AnnouncementModel> get announcements => _announcements;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll() async {
    _status = ArticlesStatus.loading;
    notifyListeners();

    await Future.wait([
      fetchArticles(),
      fetchAnnouncements(),
    ]);

    _status = ArticlesStatus.loaded;
    notifyListeners();
  }

  Future<void> fetchArticles() async {
    try {
      final response = await ApiClient.get(
        ApiConstants.articles,
        requiresAuth: false,
      );
      if (response['success'] == true && response['articles'] is List) {
        final list = response['articles'] as List;
        _articles = list.map((a) => ArticleModel.fromJson(a)).toList();
      }
    } catch (e) {
      debugPrint('[ArticlesProvider] fetchArticles error: $e');
    }
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await ApiClient.get(
        ApiConstants.announcements,
        requiresAuth: false,
      );
      if (response['success'] == true) {
        final list = (response['announcements'] ?? response['articles']) as List?;
        if (list != null) {
          _announcements = list.map((a) => AnnouncementModel.fromJson(a)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ArticlesProvider] fetchAnnouncements error: $e');
    }
  }
}

