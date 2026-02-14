double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

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
  final Map<String, dynamic>? commerce;

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
    this.commerce,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // items: puede venir como items, order_items o products (con pivot)
    List<OrderItem> parsedItems = [];
    final rawItems = json['items'] ?? json['order_items'] ?? json['orderItems'];
    final products = json['products'] as List<dynamic>?;
    if (rawItems != null && rawItems is List) {
      parsedItems = rawItems.map((item) => OrderItem.fromJson(item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})).toList();
    } else if (products != null) {
      for (final p in products) {
        if (p is Map) {
          parsedItems.add(OrderItem.fromProductPivot(Map<String, dynamic>.from(p)));
        }
      }
    }
    final createdAtRaw = json['created_at'];
    final updatedAtRaw = json['updated_at'];
    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['profile_id'] ?? 0,
      commerceId: json['commerce_id'] ?? 0,
      deliveryAgentId: json['delivery_agent_id'],
      orderNumber: json['order_number'] ?? '${json['id'] ?? ''}',
      status: (json['status'] ?? 'pending').toString(),
      subtotal: _parseDouble(json['subtotal']) > 0
          ? _parseDouble(json['subtotal'])
          : (parsedItems.isNotEmpty
              ? parsedItems.fold<double>(0, (s, i) => s + i.total)
              : _parseDouble(json['total']) - _parseDouble(json['delivery_fee'])),
      deliveryFee: _parseDouble(json['delivery_fee']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      deliveryLocation: json['delivery_location'],
      specialInstructions: json['special_instructions'] ?? json['notes'],
      estimatedDeliveryTime: createdAtRaw != null
          ? (DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()).add(const Duration(minutes: 30))
          : DateTime.now().add(const Duration(minutes: 30)),
      actualDeliveryTime: json['actual_delivery_time'] != null ? DateTime.tryParse(json['actual_delivery_time'].toString()) : null,
      createdAt: createdAtRaw != null ? (DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()) : DateTime.now(),
      updatedAt: updatedAtRaw != null ? (DateTime.tryParse(updatedAtRaw.toString()) ?? DateTime.now()) : DateTime.now(),
      items: parsedItems,
      commerce: json['commerce'],
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
      'commerce': commerce,
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
    Map<String, dynamic>? commerce,
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
      commerce: commerce ?? this.commerce,
    );
  }

  bool get isPending => status == 'pending' || status == 'pending_payment';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'pending':
      case 'pending_payment':
        return 'Pendiente de pago';
      case 'paid':
        return 'Pagado';
      case 'confirmed':
        return 'Confirmado';
      case 'preparing':
        return 'Preparando';
      case 'ready':
      case 'processing':
        return status == 'processing' ? 'En preparación' : 'Listo';
      case 'shipped':
        return 'En camino';
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
      case 'paid':
      case 'processing':
      case 'shipped':
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
    final qty = json['quantity'] ?? 0;
    final price = _parseDouble(json['price']) > 0 ? _parseDouble(json['price']) : _parseDouble(json['unit_price']);
    final tot = _parseDouble(json['total']) > 0 ? _parseDouble(json['total']) : (qty * price);
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? json['name'] ?? '',
      productImage: json['product_image'] ?? json['image'] ?? '',
      price: price,
      quantity: qty,
      total: tot,
      specialInstructions: json['special_instructions'],
    );
  }

  /// Desde products con pivot (respuesta backend)
  factory OrderItem.fromProductPivot(Map<String, dynamic> json) {
    final rawPivot = json['pivot'];
    final pivot = rawPivot is Map
        ? Map<String, dynamic>.from(rawPivot)
        : <String, dynamic>{};
    final qty = pivot['quantity'] ?? json['quantity'] ?? 0;
    final unitPrice = _parseDouble(pivot['unit_price']) > 0 ? _parseDouble(pivot['unit_price']) : _parseDouble(json['price']);
    final tot = qty * unitPrice;
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: 0,
      productId: json['id'] ?? 0,
      productName: json['name'] ?? json['product_name'] ?? '',
      productImage: json['image'] ?? json['product_image'] ?? '',
      price: unitPrice,
      quantity: qty,
      total: tot,
      specialInstructions: null,
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
