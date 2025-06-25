class CartItem {
  final int id;
  final String nombre;
  final double? precio;
  final int quantity;

  CartItem({
    required this.id,
    required this.nombre,
    this.precio,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] is int)
          ? (json['precio'] as int).toDouble()
          : (json['precio'] is String)
              ? double.tryParse(json['precio'])
              : json['precio'],
      quantity: json['quantity'] ?? 1,
    );
  }
}
