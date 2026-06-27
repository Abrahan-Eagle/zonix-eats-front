import 'package:flutter/material.dart';

/// Stub sin escáner QR (Zonix Glasses). Permite ingresar un valor manualmente.
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  QRScannerScreenState createState() => QRScannerScreenState();
}

class QRScannerScreenState extends State<QRScannerScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('El escáner QR no está disponible en esta versión. Ingresa el valor manualmente.'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ingresa el código manualmente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, _controller.text.trim()),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
