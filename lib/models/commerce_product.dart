class CommerceProduct {
  final int id;
  final int commerceId;
  final String name;
  final String description;
  final double price;
  final String? image;
  final bool available;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommerceProduct({
    required this.id,
    required this.commerceId,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommerceProduct.fromJson(Map<String, dynamic> json) {
    return CommerceProduct(
      id: json['id'] ?? 0,
      commerceId: json['commerce_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      image: json['image'],
      available: json['available'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commerce_id': commerceId,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'available': available,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CommerceProduct copyWith({
    int? id,
    int? commerceId,
    String? name,
    String? description,
    double? price,
    String? image,
    bool? available,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommerceProduct(
      id: id ?? this.id,
      commerceId: commerceId ?? this.commerceId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CommerceProduct(id: $id, name: $name, price: $price, available: $available)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommerceProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 