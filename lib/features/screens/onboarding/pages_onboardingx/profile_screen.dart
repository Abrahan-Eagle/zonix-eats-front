import 'package:flutter/material.dart';
import './address_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes guardar los datos del perfil
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>  AddressScreen(),
                ));
              },
              child: const Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}
