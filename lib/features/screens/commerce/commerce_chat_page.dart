import 'package:flutter/material.dart';

class CommerceChatPage extends StatefulWidget {
  const CommerceChatPage({Key? key}) : super(key: key);

  @override
  State<CommerceChatPage> createState() => _CommerceChatPageState();
}

class _CommerceChatPageState extends State<CommerceChatPage> {
  final List<Map<String, String>> _messages = [
    {'from': 'cliente', 'text': 'Hola, ¿está disponible la pizza familiar?'},
    {'from': 'comercio', 'text': '¡Hola! Sí, tenemos disponible.'},
  ];
  final _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'from': 'comercio', 'text': _controller.text.trim()});
      _controller.clear();
    });
    // TODO: Integrar con ChatService real
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMe = m['from'] == 'comercio';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m['text']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 