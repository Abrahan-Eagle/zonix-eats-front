  // class Restaurant {
  //   final int id;
  //   final int profileId;
  //   final String nombreLocal;
  //   final String? direccion;
  //   final String? telefono;
  //   final String? descripcion;
  //   final String? imagen;
  //   final String? pagoMovilBanco;
  //   final String? pagoMovilCedula;
  //   final String? pagoMovilTelefono;
  //   final bool abierto;


  //   Restaurant({
  //     required this.id,
  //     required this.profileId,
  //     required this.nombreLocal,
  //     required this.direccion,
  //     required this.telefono,
  //     this.descripcion,
  //     this.imagen,
  //     required this.pagoMovilBanco,
  //     required this.pagoMovilCedula,
  //     required this.pagoMovilTelefono,
  //     required this.abierto,
  //   });

  //   factory Restaurant.fromJson(Map<String, dynamic> json) {
  //     return Restaurant(
  //         id: json['id'] as int,
  //         profileId: json['profile_id'] as int,
  //         nombreLocal: json['nombre_local'] ?? '',
  //         direccion: json['direccion'] ?? '',
  //         telefono: json['telefono'] ?? '',
  //         descripcion: json['descripcion'],
  //         imagen: json['imagen'],
  //         pagoMovilBanco: json['pago_movil_banco'] ?? '',
  //         pagoMovilCedula: json['pago_movil_cedula'] ?? '',
  //         pagoMovilTelefono: json['pago_movil_telefono'] ?? '',
  //         abierto: json['abierto'] == 1 || json['abierto'] == true,
  //     );
  //   }
  // }





import 'dart:convert'; // ¡Importante! Agregar esta importación

class Restaurant {
  final int id;
  final int profileId;
  final String nombreLocal;
  final String? direccion;
  final String? telefono;
  final String? descripcion;
  final String? logoUrl;
  final String? pagoMovilBanco;
  final String? pagoMovilCedula;
  final String? pagoMovilTelefono;
  final bool abierto;
  final Map<String, dynamic>? horario;

  Restaurant({
    required this.id,
    required this.profileId,
    required this.nombreLocal,
    required this.direccion,
    required this.telefono,
    this.descripcion,
    this.logoUrl,
    required this.pagoMovilBanco,
    required this.pagoMovilCedula,
    required this.pagoMovilTelefono,
    required this.abierto,
    this.horario,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del campo horario (que puede venir como String JSON o como Map)
    Map<String, dynamic>? parsedHorario;
    if (json['horario'] != null) {
      if (json['horario'] is String) {
        try {
          // Corrección: usar jsonDecode en lugar de json.decode
          parsedHorario = Map<String, dynamic>.from(
            jsonDecode(json['horario'] as String)
          );
        } catch (e) {
          print('Error parsing horario JSON: $e');
          parsedHorario = null;
        }
      } else if (json['horario'] is Map) {
        parsedHorario = Map<String, dynamic>.from(json['horario'] as Map);
      }
    }

    return Restaurant(
      id: json['id'] as int,
      profileId: json['profile_id'] as int,
      nombreLocal: json['nombre_local'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      descripcion: json['descripcion'],
      logoUrl: json['imagen'],
      pagoMovilBanco: json['pago_movil_banco'] ?? '',
      pagoMovilCedula: json['pago_movil_cedula'] ?? '',
      pagoMovilTelefono: json['pago_movil_telefono'] ?? '',
      abierto: json['abierto'] == 1 || json['abierto'] == true,
      horario: parsedHorario,
    );
  }


}