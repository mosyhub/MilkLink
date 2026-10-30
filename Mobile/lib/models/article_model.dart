class ArticleModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    String? img;
    if (json['image'] is Map) {
      img = json['image']['url'];
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final first = (json['images'] as List).first;
      if (first is Map) img = first['url'];
    }

    return ArticleModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? '',
      imageUrl: img,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    String? img;
    if (json['image'] is Map) {
      img = json['image']['url'];
    }

    return AnnouncementModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['content'] ?? json['description'] ?? json['body'] ?? '',
      imageUrl: img,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

