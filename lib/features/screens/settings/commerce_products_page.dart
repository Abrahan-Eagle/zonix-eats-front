import 'package:flutter/material.dart';

class CommerceProductsPage extends StatelessWidget {
  const CommerceProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos del comercio')),
      body: const Center(child: Text('Gestión de productos (próximamente)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a formulario de crear producto
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar producto',
      ),
    );
  }
} 