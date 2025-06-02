import 'package:flutter/material.dart';

class GasCylinderScreen extends StatelessWidget {
  const GasCylinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bombona de Gas')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Aquí puedes gestionar la lógica para registrar una bombona
            // o redirigir a otra pantalla si es necesario.
            print('Bombona registrada.');
          },
          child: const Text('Registrar bombona de gas'),
        ),
      ),
    );
  }
}
