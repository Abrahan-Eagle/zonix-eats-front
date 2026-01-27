// Este archivo existía para manejar WebSocket manual hacia Laravel Echo Server.
// Ahora toda la lógica en tiempo casi real se maneja mediante PusherService
// (ver `lib/features/services/pusher_service.dart`), que usa pusher_channels_flutter.
//
// Mantenemos una clase mínima `WebSocketService` SOLO para compatibilidad con
// tests y mocks antiguos. No abre conexiones WebSocket reales.

class WebSocketService {
  bool get isConnected => false;

  // Compatibilidad con tests: permitir inyectar un stream de mensajes.
  void setTestMessageStream(Stream<Map<String, dynamic>>? stream) {
    // No-op: los tests pueden usarlo para simular mensajes.
  }

  Future<void> connect() async {
    // No hace nada: la app usa PusherService para tiempo real.
  }

  void disconnect() {
    // No hace nada.
  }
}

