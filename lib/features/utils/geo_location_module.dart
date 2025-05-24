import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationModule {
  // Método para obtener la ubicación actual
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('El servicio de ubicación está deshabilitado.');
      return null;
    }

    // Solicita permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Los permisos de ubicación están denegados.');
        return null;
      }
    }

    // Obtiene la ubicación actual
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('Ubicación actual: $currentPosition');
    
    return currentPosition;
  }

  // Método para construir un widget que muestre la ubicación
  Widget buildLocationWidget() {
    return FutureBuilder<Position?>(
      future: getCurrentLocation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          final position = snapshot.data!;
          return Text('Latitud: ${position.latitude}, Longitud: ${position.longitude}');
        } else {
          return const Text('No se pudo obtener la ubicación.');
        }
      },
    );
  }
}
