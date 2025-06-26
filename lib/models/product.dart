class Product {
  final int id;
  final String nombre;
  final bool disponible;
  final int? commerceId;
  final double? precio;
  final String? descripcion;
  final String? imagen;
  final String? categoria;

  Product({
    required this.id,
    required this.nombre,
    required this.disponible,
    this.commerceId,
    this.precio,
    this.descripcion,
    this.imagen,
    this.categoria,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      disponible: json['disponible'] == true || json['disponible'] == 1,
      commerceId: json['commerce_id'],
      precio: (json['precio'] is int)
          ? (json['precio'] as int).toDouble()
          : (json['precio'] is String)
              ? double.tryParse(json['precio'])
              : json['precio'],
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      categoria: json['categoria'],
    );
  }
}
