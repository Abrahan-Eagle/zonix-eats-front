import 'package:flutter/material.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otra Pantalla'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uso de RichText para renderizar TextSpan correctamente
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'ZONI',
                    style: TextStyle(
                      fontFamily: 'system-ui',
                      fontSize: 39,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(
                      fontFamily: 'system-ui',
                      fontSize: 39,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blueAccent[700]
                          : Colors.orange,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta es una pantalla de ejemplo que puedes utilizar para mostrar información adicional, '
              'opciones, o cualquier otro contenido que consideres relevante.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Lógica para mostrar un mensaje al presionar el botón
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Botón presionado!')),
                );
              },
              child: const Text('Presiona aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
