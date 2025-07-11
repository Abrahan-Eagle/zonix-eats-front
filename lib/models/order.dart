class Order {
  final int id;
  final int userId;
  final int commerceId;
  final int? deliveryAgentId;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final Map<String, dynamic>? deliveryLocation;
  final String? specialInstructions;
  final DateTime estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.commerceId,
    this.deliveryAgentId,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.deliveryLocation,
    this.specialInstructions,
    required this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      commerceId: json['commerce_id'] ?? 0,
      deliveryAgentId: json['delivery_agent_id'],
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryLocation: json['delivery_location'],
      specialInstructions: json['special_instructions'],
      estimatedDeliveryTime: DateTime.parse(json['estimated_delivery_time'] ?? DateTime.now().add(Duration(minutes: 30)).toIso8601String()),
      actualDeliveryTime: json['actual_delivery_time'] != null ? DateTime.parse(json['actual_delivery_time']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      items: (json['items'] as List<dynamic>? ?? []).map((item) => OrderItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'commerce_id': commerceId,
      'delivery_agent_id': deliveryAgentId,
      'order_number': orderNumber,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'delivery_address': deliveryAddress,
      'delivery_location': deliveryLocation,
      'special_instructions': specialInstructions,
      'estimated_delivery_time': estimatedDeliveryTime.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Order copyWith({
    int? id,
    int? userId,
    int? commerceId,
    int? deliveryAgentId,
    String? orderNumber,
    String? status,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? deliveryAddress,
    Map<String, dynamic>? deliveryLocation,
    String? specialInstructions,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commerceId: commerceId ?? this.commerceId,
      deliveryAgentId: deliveryAgentId ?? this.deliveryAgentId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'preparing':
        return 'Preparando';
      case 'ready':
        return 'Listo';
      case 'out_for_delivery':
        return 'En Camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FFA500';
      case 'confirmed':
        return '#2196F3';
      case 'preparing':
        return '#FF9800';
      case 'ready':
        return '#4CAF50';
      case 'out_for_delivery':
        return '#9C27B0';
      case 'delivered':
        return '#4CAF50';
      case 'cancelled':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;
  final String? specialInstructions;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 0,
      total: (json['total'] ?? 0.0).toDouble(),
      specialInstructions: json['special_instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
      'total': total,
      'special_instructions': specialInstructions,
    };
  }
}
