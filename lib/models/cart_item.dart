class CartItem {
  final int id;
  final String nombre;
  final double? precio;
  final int quantity;
  final String? imagen; // Nueva propiedad para la imagen
  final int? stock; // Stock disponible
  final String? category; // Categoría del producto
  final String? image; // URL de la imagen (alias para imagen)
  /// Notas de personalización: extras, preferencias e instrucciones especiales
  final String? notes;

  CartItem({
    required this.id,
    required this.nombre,
    this.precio,
    required this.quantity,
    this.imagen,
    this.stock,
    this.category,
    this.image,
    this.notes,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] is int)
          ? (json['precio'] as int).toDouble()
          : (json['precio'] is String)
              ? double.tryParse(json['precio']) ?? 0.0
              : (json['precio'] is double)
                  ? json['precio']
                  : 0.0,
      quantity: json['quantity'] ?? 1,
      imagen: json['imagen'],
      stock: json['stock'],
      category: json['category'],
      image: json['image'] ?? json['imagen'],
      notes: json['notes'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.nombre == nombre &&
        other.precio == precio &&
        other.quantity == quantity &&
        other.imagen == imagen &&
        other.stock == stock &&
        other.category == category &&
        other.image == image &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        precio.hashCode ^
        quantity.hashCode ^
        imagen.hashCode ^
        stock.hashCode ^
        category.hashCode ^
        image.hashCode ^
        notes.hashCode;
  }

  @override
  String toString() {
    return 'CartItem(id: $id, nombre: $nombre, precio: $precio, quantity: $quantity, imagen: $imagen, stock: $stock, category: $category, image: $image, notes: $notes)';
  }
}
