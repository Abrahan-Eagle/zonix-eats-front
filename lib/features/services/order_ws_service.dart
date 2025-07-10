import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderWebSocketService {
  final int orderId;
  final void Function(Map<String, dynamic> data) onMessage;
  WebSocketChannel? _channel;

  OrderWebSocketService({required this.orderId, required this.onMessage});

  void connect() {
    // Cambia la IP por la de tu servidor
    final url = 'ws://TU_IP_O_DOMINIO:6001/app/local?protocol=7&client=js&version=4.3.1&flash=false';
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen((message) {
      // Laravel Echo Server envía mensajes en formato JSON
      final data = jsonDecode(message);
      // Filtra solo los eventos del canal y tipo esperado
      if (data is Map && data['event'] == 'OrderStatusChanged' && data['channel'] == 'private-orders.$orderId') {
        onMessage(data['data']);
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
  }
} 