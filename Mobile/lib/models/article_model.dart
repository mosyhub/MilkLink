import 'package:intl/intl.dart';

// ── Shared image model used by both Announcements and Articles ──────────────
class ContentImage {
  final String? publicId;
  final String url;

  ContentImage({this.publicId, required this.url});

  factory ContentImage.fromJson(Map<String, dynamic> json) {
    return ContentImage(
      publicId: json['public_id']?.toString(),
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (publicId != null) 'public_id': publicId,
        'url': url,
      };
}

// ── Announcement ─────────────────────────────────────────────────────────────
class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final List<ContentImage> images;
  final List<String> tags;
  final String? authorName;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.tags,
    this.authorName,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    this.updatedAt,
  });

  String get formattedCreatedAt =>
      DateFormat('MMM dd, yyyy').format(createdAt);

  String? get firstImageUrl =>
      images.isNotEmpty ? images.first.url : null;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    // Parse images list
    List<ContentImage> parsedImages = [];
    if (json['images'] is List) {
      for (final img in json['images'] as List) {
        if (img is Map<String, dynamic>) {
          parsedImages.add(ContentImage.fromJson(img));
        }
      }
    } else if (json['image'] is Map) {
      final img = json['image'] as Map<String, dynamic>;
      if (img['url'] != null) {
        parsedImages.add(ContentImage.fromJson(img));
      }
    }

    // Parse tags list
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List)
          .map((t) => t?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    }

    // Parse author name
    String? authorName;
    if (json['author'] is Map) {
      final a = json['author'] as Map<String, dynamic>;
      final first = a['firstName']?.toString() ?? '';
      final last = a['lastName']?.toString() ?? '';
      authorName = '$first $last'.trim();
      if (authorName.isEmpty) authorName = a['username']?.toString();
    } else if (json['authorName'] is String) {
      authorName = json['authorName'];
    }

    return AnnouncementModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['body']?.toString() ??
          json['content']?.toString() ??
          '',
      images: parsedImages,
      tags: parsedTags,
      authorName: authorName,
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

// ── Article ──────────────────────────────────────────────────────────────────
class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final List<ContentImage> images;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.images,
    required this.isDeleted,
    required this.createdAt,
    this.updatedAt,
  });

  String get formattedCreatedAt =>
      DateFormat('MMM dd, yyyy').format(createdAt);

  String? get firstImageUrl =>
      images.isNotEmpty ? images.first.url : null;

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    List<ContentImage> parsedImages = [];
    if (json['images'] is List) {
      for (final img in json['images'] as List) {
        if (img is Map<String, dynamic>) {
          parsedImages.add(ContentImage.fromJson(img));
        }
      }
    } else if (json['image'] is Map) {
      final img = json['image'] as Map<String, dynamic>;
      if (img['url'] != null) {
        parsedImages.add(ContentImage.fromJson(img));
      }
    }

    return ArticleModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      content: json['content']?.toString() ??
          json['description']?.toString() ??
          '',
      images: parsedImages,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
