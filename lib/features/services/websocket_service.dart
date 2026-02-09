// Legacy: WebSocketService ha sido totalmente reemplazado por PusherService.
// La app no debe abrir conexiones WebSocket directas; toda la comunicación
// en tiempo real pasa por Pusher + Laravel Echo Server.
//
// Este archivo se mantiene como cascarón para que imports y tests legacy no rompan.

class WebSocketService {
  bool get isConnected => false;
  void connect() {}
  void disconnect() {}
}
