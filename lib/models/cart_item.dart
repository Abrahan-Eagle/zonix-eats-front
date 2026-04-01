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
  /// ID del comercio (requerido para crear orden)
  final int? commerceId;
  /// Identificador estable de línea remota para diferenciar personalizaciones.
  final String? lineId;

  /// Clave logica de linea para distinguir personalizaciones del mismo producto.
  /// Dos lineas con el mismo producto pero notas distintas NO deben fusionarse.
  String get lineKey {
    if (lineId != null && lineId!.trim().isNotEmpty) {
      return lineId!.trim();
    }
    final normalizedNotes = (notes ?? '').trim();
    return '$id|$normalizedNotes';
  }

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
    this.commerceId,
    this.lineId,
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
      commerceId: json['commerce_id'],
      lineId: json['line_id']?.toString(),
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
        other.notes == notes &&
        other.commerceId == commerceId &&
        other.lineId == lineId;
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
        notes.hashCode ^
        commerceId.hashCode ^
        lineId.hashCode;
  }

  @override
  String toString() {
    return 'CartItem(id: $id, nombre: $nombre, precio: $precio, quantity: $quantity, commerceId: $commerceId, notes: $notes)';
  }
}
