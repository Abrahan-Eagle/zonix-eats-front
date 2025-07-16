class CommerceOrder {
  final int id;
  final int profileId;
  final int commerceId;
  final String deliveryType;
  final String status;
  final double total;
  final String? receiptUrl;
  final String? notes;
  final String? paymentProof;
  final String? paymentMethod;
  final String? referenceNumber;
  final DateTime? paymentValidatedAt;
  final String? cancellationReason;
  final String? deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>>? orderItems;
  final Map<String, dynamic>? orderDelivery;

  CommerceOrder({
    required this.id,
    required this.profileId,
    required this.commerceId,
    required this.deliveryType,
    required this.status,
    required this.total,
    this.receiptUrl,
    this.notes,
    this.paymentProof,
    this.paymentMethod,
    this.referenceNumber,
    this.paymentValidatedAt,
    this.cancellationReason,
    this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
    this.user,
    this.orderItems,
    this.orderDelivery,
  });

  factory CommerceOrder.fromJson(Map<String, dynamic> json) {
    return CommerceOrder(
      id: json['id'] ?? 0,
      profileId: json['profile_id'] ?? 0,
      commerceId: json['commerce_id'] ?? 0,
      deliveryType: json['delivery_type'] ?? 'pickup',
      status: json['status'] ?? 'pending',
      total: (json['total'] ?? 0.0).toDouble(),
      receiptUrl: json['receipt_url'],
      notes: json['notes'],
      paymentProof: json['payment_proof'],
      paymentMethod: json['payment_method'],
      referenceNumber: json['reference_number'],
      paymentValidatedAt: json['payment_validated_at'] != null 
          ? DateTime.parse(json['payment_validated_at']) 
          : null,
      cancellationReason: json['cancellation_reason'],
      deliveryAddress: json['delivery_address'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      profile: json['profile'],
      user: json['user'],
      orderItems: json['order_items'] != null 
          ? List<Map<String, dynamic>>.from(json['order_items'])
          : null,
      orderDelivery: json['order_delivery'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'commerce_id': commerceId,
      'delivery_type': deliveryType,
      'status': status,
      'total': total,
      'receipt_url': receiptUrl,
      'notes': notes,
      'payment_proof': paymentProof,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'payment_validated_at': paymentValidatedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'delivery_address': deliveryAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile': profile,
      'user': user,
      'order_items': orderItems,
      'order_delivery': orderDelivery,
    };
  }

  CommerceOrder copyWith({
    int? id,
    int? profileId,
    int? commerceId,
    String? deliveryType,
    String? status,
    double? total,
    String? receiptUrl,
    String? notes,
    String? paymentProof,
    String? paymentMethod,
    String? referenceNumber,
    DateTime? paymentValidatedAt,
    String? cancellationReason,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? user,
    List<Map<String, dynamic>>? orderItems,
    Map<String, dynamic>? orderDelivery,
  }) {
    return CommerceOrder(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      commerceId: commerceId ?? this.commerceId,
      deliveryType: deliveryType ?? this.deliveryType,
      status: status ?? this.status,
      total: total ?? this.total,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
      paymentProof: paymentProof ?? this.paymentProof,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentValidatedAt: paymentValidatedAt ?? this.paymentValidatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
      user: user ?? this.user,
      orderItems: orderItems ?? this.orderItems,
      orderDelivery: orderDelivery ?? this.orderDelivery,
    );
  }

  // Getters útiles
  String get customerName {
    if (user != null && user!['name'] != null) {
      return user!['name'];
    }
    if (profile != null && profile!['name'] != null) {
      return profile!['name'];
    }
    return 'Cliente #$profileId';
  }

  String get customerEmail {
    if (user != null && user!['email'] != null) {
      return user!['email'];
    }
    return 'Sin email';
  }

  String get customerPhone {
    if (profile != null && profile!['phone'] != null) {
      return profile!['phone'];
    }
    return 'Sin teléfono';
  }

  List<Map<String, dynamic>> get items {
    return orderItems ?? [];
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
  }

  bool get isPendingPayment => status == 'pending_payment';
  bool get isPaid => status == 'paid';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isOnWay => status == 'on_way';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  bool get isDelivery => deliveryType == 'delivery';
  bool get isPickup => deliveryType == 'pickup';

  bool get hasPaymentProof => paymentProof != null && paymentProof!.isNotEmpty;
  bool get isPaymentValidated => paymentValidatedAt != null;

  String get statusText {
    switch (status) {
      case 'pending_payment':
        return 'Pendiente de Pago';
      case 'paid':
        return 'Pagado';
      case 'preparing':
        return 'En Preparación';
      case 'ready':
        return 'Listo';
      case 'on_way':
        return 'En Camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String get deliveryTypeText {
    switch (deliveryType) {
      case 'delivery':
        return 'Entrega';
      case 'pickup':
        return 'Recoger';
      default:
        return 'Desconocido';
    }
  }

  @override
  String toString() {
    return 'CommerceOrder(id: $id, customer: $customerName, total: \$${total.toStringAsFixed(2)}, status: $statusText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommerceOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 