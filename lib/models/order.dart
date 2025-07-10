class Order {
  final int id;
  final String? status;
  final double? total;
  final DateTime? createdAt;
  final List<OrderItem>? items;
  final String? comprobanteUrl;
  final String? estado;

  Order({
    required this.id,
    this.status,
    this.total,
    this.createdAt,
    this.items,
    this.comprobanteUrl,
    this.estado,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      status: json['status'],
      total: (json['total'] is int)
          ? (json['total'] as int).toDouble()
          : (json['total'] is String)
              ? double.tryParse(json['total'])
              : json['total'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      items: (json['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList(),
      comprobanteUrl: json['comprobante_url'],
      estado: json['estado'],
    );
  }
}

class OrderItem {
  final int id;
  final String? nombre;
  final int? quantity;
  final double? precio;

  OrderItem({
    required this.id,
    this.nombre,
    this.quantity,
    this.precio,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      nombre: json['nombre'],
      quantity: json['quantity'],
      precio: (json['precio'] is int)
          ? (json['precio'] as int).toDouble()
          : (json['precio'] is String)
              ? double.tryParse(json['precio'])
              : json['precio'],
    );
  }
}
