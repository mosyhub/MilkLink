class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool seen;
  final DateTime notifiedAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.seen,
    required this.notifiedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      seen: json['seen'] ?? false,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.tryParse(json['notifiedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

