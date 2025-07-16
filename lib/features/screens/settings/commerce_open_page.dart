import 'package:flutter/material.dart';

class CommerceOpenPage extends StatefulWidget {
  const CommerceOpenPage({Key? key}) : super(key: key);

  @override
  State<CommerceOpenPage> createState() => _CommerceOpenPageState();
}

class _CommerceOpenPageState extends State<CommerceOpenPage> {
  bool _open = false;
  bool _loading = false;
  String? _error;
  String? _success;

  void _submit() async {
    setState(() { _loading = true; _error = null; _success = null; });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _success = _open ? '¡El comercio está ABIERTO!' : 'El comercio está CERRADO.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _open ? Colors.green : Colors.red;
    final text = _open ? 'ABIERTO' : 'CERRADO';
    return Scaffold(
      appBar: AppBar(title: const Text('Estado abierto/cerrado')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Estado actual: ', style: TextStyle(fontSize: 18)),
                Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 12),
                Switch(
                  value: _open,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (v) => setState(() => _open = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_success != null) Text(_success!, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
} 