import 'package:flutter/material.dart';

class StatusProvider with ChangeNotifier {
  
  // Color getStatusColor(String status) {
  //   switch (status) {
  //     case 'pending':
  //       return Colors.amber;
  //     case 'verifying':
  //       return Colors.blueAccent;
  //     case 'waiting':
  //       return Colors.purple;
  //     case 'dispatched':
  //       return Colors.green;
  //     case 'canceled':
  //       return Colors.red;
  //     case 'expired':
  //       return Colors.orange;
  //     default:
  //       return Colors.black;
  //   }
  // }


    Color getStatusColor(String status) {
      switch (status) {
        case 'pending': // Amarillo: asociado con alerta o algo en espera.
          return const Color(0xFFFFC107); // Tono más claro para mejor contraste.
        case 'verifying': // Azul: relacionado con confianza y verificación.
          return const Color(0xFF0056A5); // Tono más oscuro que el base.
        case 'waiting': // Morado: evoca calma o espera.
          return const Color(0xFF6A0DAD); // Contrasta bien y es significativo.
        case 'dispatched': // Verde: progreso o completado.
          return const Color(0xFF2ECC71); // Verde brillante para resaltar.
        case 'canceled': // Rojo: error o cancelación.
          return const Color(0xFFD32F2F); // Rojo fuerte y distinguible.
        case 'expired': // Naranja: tiempo agotado.
          return const Color(0xFFFF5722); // Naranja intenso para urgencia.
        default: // Negro: desconocido o estado sin clasificar.
          return const Color(0xFF424242); // Gris oscuro para neutralidad.
      }
  }


  AssetImage getStatusIcon(String status) {
    return const AssetImage('assets/images/splash_logo_dark.png'); // Puedes personalizar según el estado
  }


  String getStatusSpanish(String status) {
    switch (status) {
      case 'pending':
        return 'PENDIENTE';
      case 'verifying':
        return 'VERIFICANDO';
      case 'waiting':
        return 'ESPERANDO';
      case 'dispatched':
        return 'DESPACHADO';
      case 'canceled':
        return 'CANCELADO';
      case 'expired':
        return 'EXPIRADO';
      default:
        return 'ESTADO DESCONOCIDO';
    }
  }
}
