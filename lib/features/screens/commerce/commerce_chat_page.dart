import 'package:flutter/material.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';
import 'package:zonix/features/services/chat_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceChatPage extends StatefulWidget {
  const CommerceChatPage({super.key});

  @override
  State<CommerceChatPage> createState() => _CommerceChatPageState();
}

class _CommerceChatPageState extends State<CommerceChatPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ChatService();
      final list = await service.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _loading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chat con clientes')),
      body: _conversations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay conversaciones'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, i) {
                  final c = _conversations[i] is Map
                      ? _conversations[i] as Map
                      : <String, dynamic>{};
                  final participants = c['participants'] as List? ?? [];
                  String customerName = 'Cliente';
                  for (final p in participants) {
                    if (p is Map && p['role'] == 'customer') {
                      customerName = p['name']?.toString() ?? 'Cliente';
                      break;
                    }
                  }
                  final lastMsg = c['last_message'];
                  final lastMsgText = lastMsg is Map
                      ? (lastMsg['content'] ?? '').toString()
                      : (c['last_message'] ?? '').toString();
                  final orderId = c['order_id'] ?? c['id'];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(customerName),
                    subtitle: Text(lastMsgText.isNotEmpty ? lastMsgText : 'Sin mensajes'),
                    trailing: (c['unread_count'] as int? ?? 0) > 0
                        ? CircleAvatar(
                            radius: 12,
                            child: Text(
                              '${c['unread_count']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          )
                        : null,
                    onTap: () {
                      if (orderId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommerceChatMessagesPage(
                              orderId: orderId is int ? orderId : int.tryParse(orderId.toString()) ?? 0,
                              customerName: customerName,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
