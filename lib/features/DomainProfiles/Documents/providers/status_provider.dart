import 'package:flutter/material.dart';

class StatusProvider with ChangeNotifier {
  
  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'verifying':
        return Colors.blueAccent;
      case 'waiting':
        return Colors.purple;
      case 'dispatched':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.black;
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
