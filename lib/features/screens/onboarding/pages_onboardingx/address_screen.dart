import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import './document_screen.dart';

class AddressScreen extends StatelessWidget {
  AddressScreen({super.key});
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dirección')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            ElevatedButton(
              onPressed: () async {
                LocationSettings locationSettings = const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 10,
                );

                try {
                  Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
                  print('Ubicación obtenida: $position');
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>  DocumentScreen(),
                  ));
                } catch (e) {
                  print('Error al obtener la ubicación: $e');
                }
              },
              child: const Text('Usar ubicación actual'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DocumentScreen(),
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
