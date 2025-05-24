import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './gas_cylinder_screen.dart';

class DocumentScreen extends StatelessWidget {
  DocumentScreen({super.key});
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                _image = await _picker.pickImage(source: ImageSource.gallery);
                if (_image != null) {
                  print('Imagen seleccionada: ${_image!.path}');
                }
              },
              child: const Text('Cargar documento'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const GasCylinderScreen(),
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
