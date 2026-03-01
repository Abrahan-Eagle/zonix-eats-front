import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  QRScannerScreenState createState() => QRScannerScreenState();
}

class QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;

  void _onDetect(BarcodeCapture barcode) {
    // Usa barcode.barcodes para acceder a los códigos escaneados
    final List<Barcode> barcodes = barcode.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue; // Accede al primer valor escaneado
      if (rawValue != null) {
        _stopScanning(rawValue);
      } else {
        _showSnackBar('Código QR inválido');
      }
    } else {
      _showSnackBar('No se detectaron códigos');
    }
  }

  void _stopScanning(String value) {
    setState(() {
      _isScanning = false;
    });
    Navigator.pop(context, value); // Retorna el valor escaneado
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context), // Cerrar el escáner manualmente
          ),
        ],
      ),
      body: _isScanning
          ? MobileScanner(
              onDetect: _onDetect,
            )
          : const Center(child:  Text('Escaneo detenido.')),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class QRScannerScreen extends StatelessWidget {
//   const QRScannerScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Escanear QR')),
//       body: MobileScanner(
//         onDetect: (BarcodeCapture barcode) {
//           // Usa barcode.barcodes para acceder a los códigos escaneados
//           final List<Barcode> barcodes = barcode.barcodes;
//           if (barcodes.isNotEmpty) {
//             final String? rawValue = barcodes.first.rawValue; // Accede al primer valor escaneado
//             if (rawValue != null) {
//               Navigator.pop(context, rawValue); // Retorna el valor escaneado
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Código QR inválido')),
//               );
//             }
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('No se detectaron códigos')),
//             );
//           }
//         },
//       ),
//     );
//   }
// }
