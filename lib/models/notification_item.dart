class NotificationItem {
  final int? id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final DateTime? readAt;
  final String? type;

  NotificationItem({
    this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.readAt,
    this.type,
  });

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      receivedAt: DateTime.tryParse(json['created_at'] ?? json['receivedAt'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
    if (type != null) 'type': type,
  };
}
