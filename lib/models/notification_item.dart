class NotificationItem {
  final String title;
  final String body;
  final DateTime receivedAt;

  NotificationItem({
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      receivedAt: DateTime.tryParse(json['receivedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
  };
}
