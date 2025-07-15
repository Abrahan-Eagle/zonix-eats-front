class CommerceOrder {
  final int id;
  final String status;
  final double total;
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic> items;
  final Map<String, dynamic>? customer;

  CommerceOrder({
    required this.id,
    required this.status,
    required this.total,
    this.receiptUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.customer,
  });

  factory CommerceOrder.fromJson(Map<String, dynamic> json) {
    double parseTotal(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    return CommerceOrder(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      total: parseTotal(json['total']),
      receiptUrl: json['receipt_url'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      items: json['order_items'] ?? [],
      customer: json['profile'] ?? {},
    );
  }
} 