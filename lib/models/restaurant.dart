class Restaurant {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final String? imagen;

  Restaurant({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.imagen,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      direccion: json['direccion'],
      imagen: json['imagen'],
    );
  }
}
