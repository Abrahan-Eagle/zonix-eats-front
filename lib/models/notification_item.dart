import 'dart:convert';

class NotificationItem {
  final int? id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final DateTime? readAt;
  final String? type;
  final Map<String, dynamic>? data;

  NotificationItem({
    this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.readAt,
    this.type,
    this.data,
  });

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? dataMap;
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) {
          dataMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      receivedAt: DateTime.tryParse(json['created_at'] ?? json['receivedAt'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      type: json['type']?.toString(),
      data: dataMap,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
    if (type != null) 'type': type,
    if (data != null) 'data': data,
  };
}
