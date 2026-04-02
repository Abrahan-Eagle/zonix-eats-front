import 'dart:async';
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
  StreamSubscription<Map<String, dynamic>>? _pusherSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages(silent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToPusher());
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    PusherService.instance.unsubscribeFromChannel('private-orders.${widget.orderId}');
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToPusher() async {
    final ok = await PusherService.instance.subscribeToOrderChat(widget.orderId);
    
    if (ok && mounted) {
      _pusherSubscription?.cancel();
      _pusherSubscription = PusherService.instance.eventStream.listen((event) {
        final eventName =
            (event['canonicalEventName'] ?? event['eventName'])?.toString() ?? '';
        final channelName = event['channelName']?.toString() ?? '';

        if (channelName == 'private-orders.${widget.orderId}') {
          if (!mounted) return;
          if (eventName.contains('NewMessage') ||
              eventName.contains('OrderStatusChanged') ||
              eventName.contains('PaymentValidated')) {
            _loadMessages(silent: true);
          }
        }
      });
    }
  }

  /// [silent]: recarga por Pusher sin pantalla de carga (no tapa el chat).
  Future<void> _loadMessages({required bool silent}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _orderService.getOrderMessages(widget.orderId);
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
          if (silent) _error = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _error = e.toString().replaceFirst('Exception: ', '');
          }
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
        _textController.text = text; // Restaurar texto para que el usuario no lo pierda
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
        foregroundColor: AppColors.white,
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
              onPressed: () => _loadMessages(silent: false),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMutedGray),
            SizedBox(height: 16),
            Text(
              'No hay mensajes. Escribe para contactar al comercio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMessages(silent: false),
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

          final senderType = m['sender_type']?.toString() ?? '';
          final senderName = m['sender_name']?.toString() ?? '';
          final roleLabel = _roleBadgeLabel(senderType, senderName);

          return Align(
            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn && roleLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      roleLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleBadgeColor(senderType)),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn ? AppColors.blue : AppColors.textMutedGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: TextStyle(
                          color: isOwn ? AppColors.white : AppColors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: isOwn ? AppColors.white70 : AppColors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _roleBadgeLabel(String senderType, String senderName) {
    final name = senderName.isNotEmpty ? senderName : null;
    switch (senderType) {
      case 'restaurant':
        return name != null ? '$name (Comercio)' : 'Comercio';
      case 'delivery_agent':
        return name != null ? '$name (Delivery)' : 'Delivery';
      case 'admin':
        return name != null ? '$name (Admin)' : 'Admin';
      case 'customer':
        return name != null ? '$name (Cliente)' : 'Cliente';
      default:
        return name ?? '';
    }
  }

  Color _roleBadgeColor(String senderType) {
    switch (senderType) {
      case 'restaurant':
        return AppColors.orange;
      case 'delivery_agent':
        return AppColors.purple;
      case 'admin':
        return AppColors.red;
      case 'customer':
        return AppColors.blue;
      default:
        return AppColors.textMutedGray;
    }
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(
            color: AppColors.black12,
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
