class CommerceProduct {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final bool available;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommerceProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommerceProduct.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    return CommerceProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      image: json['image'],
      available: json['available'] ?? json['disponible'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'image': image,
    'available': available,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
} 