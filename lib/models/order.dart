import 'package:zonix/features/utils/safe_parse.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Backend envía minutos (int). Compat: string numérica o ISO8601 vs `created_at`.
int? _parseEstimatedDeliveryMinutes(Map<String, dynamic> json) {
  final v = json['estimated_delivery_time'];
  if (v == null) return null;
  if (v is int || v is num) {
    final m = safeInt(v, 0);
    return m > 0 ? m : null;
  }
  if (v is String) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return null;
    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      return asInt > 0 ? asInt : null;
    }
    final dt = DateTime.tryParse(trimmed);
    if (dt != null) {
      final createdRaw = json['created_at'];
      final created = createdRaw != null
          ? DateTime.tryParse(createdRaw.toString())
          : null;
      if (created != null) {
        final diff = dt.difference(created).inMinutes;
        return diff > 0 ? diff : null;
      }
    }
  }
  return null;
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
  /// Minutos estimados hasta la entrega (API: `estimated_delivery_time` entero).
  final int? estimatedDeliveryMinutes;
  final DateTime? actualDeliveryTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final Map<String, dynamic>? commerce;
  final String? deliveryType;
  final bool approvedForPayment;
  final double deliveryPaymentAmount;
  final double commissionAmount;
  final double cancellationPenalty;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? receiptUrl;
  final String? paymentProof;
  final String? referenceNumber;
  final DateTime? paymentValidatedAt;
  final DateTime? paymentProofUploadedAt;
  final List<Map<String, dynamic>> orderPayments;

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
    this.estimatedDeliveryMinutes,
    this.actualDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.commerce,
    this.deliveryType,
    this.approvedForPayment = false,
    this.deliveryPaymentAmount = 0.0,
    this.commissionAmount = 0.0,
    this.cancellationPenalty = 0.0,
    this.cancelledBy,
    this.cancellationReason,
    this.receiptUrl,
    this.paymentProof,
    this.referenceNumber,
    this.paymentValidatedAt,
    this.paymentProofUploadedAt,
    this.orderPayments = const [],
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
      status: (json['status'] ?? 'pending_payment').toString(),
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
      estimatedDeliveryMinutes: _parseEstimatedDeliveryMinutes(json),
      actualDeliveryTime: json['actual_delivery_time'] != null ? DateTime.tryParse(json['actual_delivery_time'].toString()) : null,
      createdAt: createdAtRaw != null ? (DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()) : DateTime.now(),
      updatedAt: updatedAtRaw != null ? (DateTime.tryParse(updatedAtRaw.toString()) ?? DateTime.now()) : DateTime.now(),
      items: parsedItems,
      commerce: json['commerce'],
      deliveryType: json['delivery_type']?.toString(),
      approvedForPayment: json['approved_for_payment'] == true || json['approved_for_payment'] == 1,
      deliveryPaymentAmount: _parseDouble(json['delivery_payment_amount']),
      commissionAmount: _parseDouble(json['commission_amount']),
      cancellationPenalty: _parseDouble(json['cancellation_penalty']),
      cancelledBy: json['cancelled_by']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      receiptUrl: json['receipt_url']?.toString(),
      paymentProof: json['payment_proof']?.toString(),
      referenceNumber: json['reference_number']?.toString(),
      paymentValidatedAt: json['payment_validated_at'] != null ? DateTime.tryParse(json['payment_validated_at'].toString()) : null,
      paymentProofUploadedAt: json['payment_proof_uploaded_at'] != null ? DateTime.tryParse(json['payment_proof_uploaded_at'].toString()) : null,
      orderPayments: (json['order_payments'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
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
      if (estimatedDeliveryMinutes != null)
        'estimated_delivery_time': estimatedDeliveryMinutes,
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'commerce': commerce,
      'delivery_type': deliveryType,
      'approved_for_payment': approvedForPayment,
      'delivery_payment_amount': deliveryPaymentAmount,
      'commission_amount': commissionAmount,
      'cancellation_penalty': cancellationPenalty,
      'cancelled_by': cancelledBy,
      'cancellation_reason': cancellationReason,
      'receipt_url': receiptUrl,
      'payment_proof': paymentProof,
      'reference_number': referenceNumber,
      'payment_validated_at': paymentValidatedAt?.toIso8601String(),
      'payment_proof_uploaded_at': paymentProofUploadedAt?.toIso8601String(),
      'order_payments': orderPayments,
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
    int? estimatedDeliveryMinutes,
    DateTime? actualDeliveryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
    Map<String, dynamic>? commerce,
    String? deliveryType,
    bool? approvedForPayment,
    double? deliveryPaymentAmount,
    double? commissionAmount,
    double? cancellationPenalty,
    String? cancelledBy,
    String? cancellationReason,
    String? receiptUrl,
    String? paymentProof,
    String? referenceNumber,
    DateTime? paymentValidatedAt,
    DateTime? paymentProofUploadedAt,
    List<Map<String, dynamic>>? orderPayments,
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
      estimatedDeliveryMinutes:
          estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      commerce: commerce ?? this.commerce,
      deliveryType: deliveryType ?? this.deliveryType,
      approvedForPayment: approvedForPayment ?? this.approvedForPayment,
      deliveryPaymentAmount: deliveryPaymentAmount ?? this.deliveryPaymentAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      cancellationPenalty: cancellationPenalty ?? this.cancellationPenalty,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentProof: paymentProof ?? this.paymentProof,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentValidatedAt: paymentValidatedAt ?? this.paymentValidatedAt,
      paymentProofUploadedAt: paymentProofUploadedAt ?? this.paymentProofUploadedAt,
      orderPayments: orderPayments ?? this.orderPayments,
    );
  }

  Map<String, dynamic>? get foodPayment => orderPayments.cast<Map<String, dynamic>?>().firstWhere((p) => p?['type'] == 'food', orElse: () => null);
  Map<String, dynamic>? get deliveryPaymentData => orderPayments.cast<Map<String, dynamic>?>().firstWhere((p) => p?['type'] == 'delivery', orElse: () => null);
  bool get hasFoodProof => foodPayment?['payment_proof'] != null;
  bool get hasDeliveryProof => deliveryPaymentData?['payment_proof'] != null;
  bool get foodValidated => foodPayment?['validated_at'] != null;
  bool get deliveryValidated => deliveryPaymentData?['validated_at'] != null;
  bool get foodRejected => foodPayment?['rejected_at'] != null;
  bool get deliveryRejected => deliveryPaymentData?['rejected_at'] != null;
  bool get needsDeliveryPayment => deliveryType == 'delivery' && deliveryFee > 0 && deliveryPaymentData != null;

  bool get isPickup => deliveryType == 'pickup';
  bool get isDeliveryOrder => deliveryType == 'delivery';

  String get commerceName {
    if (commerce is Map) {
      final name = (commerce as Map)['business_name'] ?? (commerce as Map)['name'] ?? '';
      return name.toString().trim();
    }
    return '';
  }

  String get commerceAddress {
    if (commerce is Map) {
      final addr = (commerce as Map)['address'] ?? '';
      return addr.toString().trim();
    }
    return '';
  }

  bool get isPending => status == 'pending_payment' || status == 'pending';
  bool get isPendingPayment => status == 'pending_payment' || status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isConfirmed => status == 'paid';
  bool get isPreparing => status == 'processing' || status == 'preparing';
  bool get isProcessing => status == 'processing' || status == 'preparing';
  bool get isReady => status == 'processing' || status == 'ready';
  bool get isShipped => status == 'shipped';
  bool get isOutForDelivery => status == 'shipped' || status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return 'Pendiente de pago';
      case 'paid':
      case 'confirmed':
        return 'Pagado';
      case 'processing':
      case 'preparing':
      case 'ready':
        return 'En preparación';
      case 'shipped':
      case 'out_for_delivery':
      case 'on_way':
        return isPickup ? 'Listo para recoger' : 'En camino';
      case 'delivered':
        return isPickup ? 'Recogido' : 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return '#FFA500';
      case 'paid':
      case 'confirmed':
        return '#2196F3';
      case 'processing':
      case 'preparing':
      case 'ready':
        return '#FF9800';
      case 'shipped':
      case 'out_for_delivery':
      case 'on_way':
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
