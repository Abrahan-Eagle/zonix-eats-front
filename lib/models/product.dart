class ProductExtra {
  final int id;
  final String name;
  final double price;

  ProductExtra({required this.id, required this.name, required this.price});

  factory ProductExtra.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    return ProductExtra(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: parseDouble(json['price']),
    );
  }
}

class ProductPreference {
  final int id;
  final String name;

  ProductPreference({required this.id, required this.name});

  factory ProductPreference.fromJson(Map<String, dynamic> json) {
    return ProductPreference(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Product {
  final int id;
  final int commerceId;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String image;
  final String category;
  final bool isAvailable;
  final int stock;
  final List<String> tags;
  final Map<String, dynamic>? nutritionalInfo;
  final List<String> allergens;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final int preparationTime;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductExtra> extras;
  final List<ProductPreference> preferences;

  Product({
    required this.id,
    required this.commerceId,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.image,
    required this.category,
    required this.isAvailable,
    required this.stock,
    required this.tags,
    this.nutritionalInfo,
    required this.allergens,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.preparationTime,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.extras = const [],
    this.preferences = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return Product(
      id: json['id'] ?? 0,
      commerceId: json['commerce_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parseDouble(json['price']),
      originalPrice: json['original_price'] != null ? parseDouble(json['original_price']) : null,
      image: json['image'] ?? '',
      category: json['category'] is Map
          ? (json['category']['name'] ?? '')
          : (json['category']?.toString() ?? ''),
      isAvailable: json['available'] ?? json['is_available'] ?? false,
      stock: json['stock'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      nutritionalInfo: json['nutritional_info'],
      allergens: List<String>.from(json['allergens'] ?? []),
      isVegetarian: json['is_vegetarian'] ?? false,
      isVegan: json['is_vegan'] ?? false,
      isGlutenFree: json['is_gluten_free'] ?? false,
      preparationTime: json['preparation_time'] ?? 0,
      rating: parseDouble(json['rating']),
      reviewCount: json['review_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      extras: (json['extras'] as List?)
              ?.map((e) => ProductExtra.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: (json['preferences'] as List?)
              ?.map((e) => ProductPreference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commerce_id': commerceId,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'image': image,
      'category': category,
      'is_available': isAvailable,
      'stock': stock,
      'tags': tags,
      'nutritional_info': nutritionalInfo,
      'allergens': allergens,
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_gluten_free': isGlutenFree,
      'preparation_time': preparationTime,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    int? commerceId,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? image,
    String? category,
    bool? isAvailable,
    int? stock,
    List<String>? tags,
    Map<String, dynamic>? nutritionalInfo,
    List<String>? allergens,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    int? preparationTime,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductExtra>? extras,
    List<ProductPreference>? preferences,
  }) {
    return Product(
      id: id ?? this.id,
      commerceId: commerceId ?? this.commerceId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      image: image ?? this.image,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      tags: tags ?? this.tags,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      allergens: allergens ?? this.allergens,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      extras: extras ?? this.extras,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  double get discountPercentage => hasDiscount ? ((originalPrice! - price) / originalPrice! * 100) : 0;
}
