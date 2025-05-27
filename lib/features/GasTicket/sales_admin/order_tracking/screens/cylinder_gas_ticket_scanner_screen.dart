import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zonix/features/GasTicket/dispatch_ticket_button/api/dispatch_ticket_service.dart';

class GasCylindersScreen extends StatefulWidget {


  const GasCylindersScreen({super.key});

  @override
  GasCylindersScreenState createState() => GasCylindersScreenState();
}

class GasCylindersScreenState extends State<GasCylindersScreen> {
  late ApiService apiService;
  String scannedData = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    resetScreen();
  }

  void resetScreen() {
    setState(() {
      scannedData = '';
      isLoading = false;
    });
  }

 Future<void> _handleScan(Barcode barcode) async {
  setState(() {
    scannedData = barcode.rawValue?.trim() ?? 'Unknown';
    isLoading = true;
  });

  try {
    // Llama a la API para procesar el código escaneado
    final result = await apiService.scanCylinderAdminSale(scannedData);

    
    if (result != null && result['data'] != null && result['data'] is List && result['data'].isNotEmpty) {
  
      final gasCylinderCode = result['data'][0]; // 'data' es una lista de strings, accede directamente

      if (gasCylinderCode != null && gasCylinderCode.isNotEmpty) {
       
        Navigator.of(context).pop({
          'gasCylinderCode': gasCylinderCode, // Envía el gasCylinderCode correcto
        });
      } else {
        _showMessage("Código de la bombona no disponible.");
      }
    } else {
      _showMessage("No se encontraron datos válidos para la bombona.");
    }
  } catch (e) {
    // Muestra un mensaje de error si ocurre algún problema
    _showMessage("Ocurrió un error al procesar el escaneo: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildMobileScanner(context),
    );
  }

  Widget _buildMobileScanner(BuildContext context) {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: MobileScanner(
          onDetect: (BarcodeCapture barcodeCapture) {
            if (barcodeCapture.barcodes.isNotEmpty) {
              final Barcode barcode = barcodeCapture.barcodes.first;
              _handleScan(barcode);
            }
          },
        ),
      ),
    );
  }
}