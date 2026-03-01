import 'package:flutter/material.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Pantalla de chat con el comercio para una orden (comprador).
/// Usa Pusher para recibir mensajes en tiempo real.
/// Permite al comprador comunicarse cuando hay problemas (ej. falta ingredientes).
class BuyerOrderChatPage extends StatefulWidget {
  const BuyerOrderChatPage({
    super.key,
    required this.orderId,
    this.commerceName = 'Comercio',
  });

  final int orderId;
  final String commerceName;

  @override
  State<BuyerOrderChatPage> createState() => _BuyerOrderChatPageState();
}

class _BuyerOrderChatPageState extends State<BuyerOrderChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OrderService _orderService = OrderService();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToPusher();
  }

  @override
  void dispose() {
    PusherService.instance.unsubscribeFromChannel('private-orders.${widget.orderId}');
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToPusher() {
    PusherService.instance.subscribeToOrderChat(
      widget.orderId,
      onNewMessage: (eventName, data) {
        if (eventName == 'NewMessage' && mounted) {
          _loadMessages();
        }
      },
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _orderService.getOrderMessages(widget.orderId);
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _textController.clear();

    try {
      await _orderService.sendOrderMessage(widget.orderId, text);
      if (mounted) {
        final msg = <String, dynamic>{
          'content': text,
          'is_own_message': true,
          'created_at': DateTime.now().toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        setState(() {
          _messages.add(msg);
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Orden #${widget.orderId}'),
        backgroundColor: AppColors.headerGradientStart(context),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay mensajes. Escribe para contactar al comercio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _messages.length,
        itemBuilder: (context, i) {
          final m = _messages[i];
          final isOwn = m['is_own_message'] == true;
          final content = m['content']?.toString() ?? '';
          String time = (m['created_at'] ?? m['timestamp'] ?? '').toString();
          if (time.length > 8 && time.contains('T')) {
            try {
              final dt = DateTime.parse(time);
              time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}
          }

          return Align(
            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isOwn ? AppColors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isOwn ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isOwn ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_sending,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _sendMessage,
            icon: _sending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
