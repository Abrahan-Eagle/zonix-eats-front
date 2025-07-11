class Commerce {
  final int id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String logo;
  final bool isActive;
  final String category;
  final double rating;
  final int reviewCount;
  final String openingHours;
  final double deliveryFee;
  final int deliveryTime;
  final double minimumOrder;
  final List<String> paymentMethods;
  final List<String> cuisines;
  final Map<String, dynamic> location;
  final DateTime createdAt;
  final DateTime updatedAt;

  Commerce({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.logo,
    required this.isActive,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.openingHours,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.minimumOrder,
    required this.paymentMethods,
    required this.cuisines,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Commerce.fromJson(Map<String, dynamic> json) {
    return Commerce(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      logo: json['logo'] ?? '',
      isActive: json['is_active'] ?? false,
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      openingHours: json['opening_hours'] ?? '',
      deliveryFee: (json['delivery_fee'] ?? 0.0).toDouble(),
      deliveryTime: json['delivery_time'] ?? 0,
      minimumOrder: (json['minimum_order'] ?? 0.0).toDouble(),
      paymentMethods: List<String>.from(json['payment_methods'] ?? []),
      cuisines: List<String>.from(json['cuisines'] ?? []),
      location: json['location'] ?? {},
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'logo': logo,
      'is_active': isActive,
      'category': category,
      'rating': rating,
      'review_count': reviewCount,
      'opening_hours': openingHours,
      'delivery_fee': deliveryFee,
      'delivery_time': deliveryTime,
      'minimum_order': minimumOrder,
      'payment_methods': paymentMethods,
      'cuisines': cuisines,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Commerce copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? logo,
    bool? isActive,
    String? category,
    double? rating,
    int? reviewCount,
    String? openingHours,
    double? deliveryFee,
    int? deliveryTime,
    double? minimumOrder,
    List<String>? paymentMethods,
    List<String>? cuisines,
    Map<String, dynamic>? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Commerce(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      openingHours: openingHours ?? this.openingHours,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      cuisines: cuisines ?? this.cuisines,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 