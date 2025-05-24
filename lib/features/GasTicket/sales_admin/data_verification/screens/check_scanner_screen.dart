import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zonix_eats/features/GasTicket/sales_admin/data_verification/api/check_service.dart';
import 'package:zonix_eats/features/DomainProfiles/Documents/screens/document_list_screen.dart';
import 'package:zonix_eats/features/DomainProfiles/Emails/screens/email_list_screen.dart';
import 'package:zonix_eats/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/screens/gas_cylinder_list_screen.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix_eats/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:logger/logger.dart'; // Librería Logger para depuración
import 'package:shared_preferences/shared_preferences.dart';

class CheckScannerScreen extends StatefulWidget {
  const CheckScannerScreen({super.key});

  @override
  CheckScannerScreenState createState() => CheckScannerScreenState();
}

class CheckScannerScreenState extends State<CheckScannerScreen> {
  late ApiService apiService;
  final logger = Logger(); // Instancia de logger para depuración
  String scannedData = ''; // Datos escaneados
  Map<String, dynamic>? checkData; // Datos del backend
  bool isProcessing = false; // Para evitar procesos simultáneos
  bool isScanActive = true; // Estado para controlar si el QR está activo o no
  final GlobalKey qrKey = GlobalKey(); // Clave para reiniciar el MobileScanner

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadScannedData(); // Cargar el scannedData almacenado previamente
  }

  // Cargar el scannedData desde el almacenamiento local
  _loadScannedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      scannedData = prefs.getString('scannedData') ?? ''; // Cargar el valor
    });
  }

  // Guardar el scannedData en el almacenamiento local
  _saveScannedData(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('scannedData', data);
  }

  // Detener el escáner al salir de la pantalla
  @override
  void dispose() {
    isScanActive = false;
    super.dispose();
  }

  void _onScan(Barcode barcode) async {
    if (!isScanActive) return; // Evitar escaneos simultáneos si no está activo

    final String? rawValue = barcode.rawValue;
    logger.i('Código QR detectado: $rawValue'); // Log del código detectado

    if (rawValue == null) {
      _showMessage('Error: Código QR inválido.');
      return;
    }

    // Almacenar el scannedData en el almacenamiento local
    await _saveScannedData(rawValue);

    setState(() {
      scannedData = rawValue;
      isScanActive = false; // Desactivar el QR mientras se procesa
    });

    // Enviar el valor a la API
    await _verifyData();
  }

  Future<void> _verifyData() async {
    if (scannedData.isEmpty) {
      _showMessage('Error: No scanned data available.');
      return;
    }

    try {
      // Llamar a la API para verificar el scannedData
      logger.i('Enviando scannedData a la API: $scannedData');
      var result = await apiService.verifyCheck(int.parse(scannedData));

      // Revisar la respuesta de la API
      logger.i('Respuesta del backend: $result');
      setState(() {
        checkData = result;
      });

      if (checkData != null && checkData!.containsKey('status')) {
        // Si el status es success
        if (checkData!['status'] == 'success') {
          await _redirectToModule(checkData!['data']); // Redirigir al módulo correspondiente
        } else {
          // Si el status es error, reactiva el escáner QR
          setState(() {
            isScanActive = true;
          });
          _showMessage('Error: ${checkData!['message']}');
        }
      }
    } catch (e) {
      logger.e('Error al procesar el código QR: $e');
      _showMessage('Error: ${e.toString()}');
      setState(() {
        isScanActive = true; // Reactivar el escáner en caso de error
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _redirectToModule(String dataKey) async {
    final userId = int.parse(scannedData);
    const statusId = true;  // Definir statusId como true

    logger.i('Redirigiendo al módulo correspondiente: $dataKey');

    // Detener el escáner antes de navegar
    setState(() {
      isScanActive = false;
    });

    switch (dataKey) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePagex(userId: userId, statusId: statusId)),
        ).then((_) => _checkStatusOnBack());
        break;
      case 'addresses':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddressPage(userId: userId, statusId: statusId)),
        ).then((_) => _checkStatusOnBack());
        break;
      case 'gasCylinders':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GasCylinderListScreen(userId: userId, statusId: statusId)),
        ).then((_) => _checkStatusOnBack());
        break;
      case 'documents':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DocumentListScreen(userId: userId, statusId: statusId)),
        ).then((_) => _checkStatusOnBack());
        break;
      case 'phones':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PhoneScreen(userId: userId, statusId: statusId)),
        ).then((_) => _checkStatusOnBack());
        break;
      case 'emails':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EmailListScreen(userId: userId, statusId: statusId)),
        ).then((_) => _checkStatusOnBack());
        break;
      default:
        logger.w('Módulo desconocido para la clave de datos: $dataKey');
        _showMessage('Unknown data key.');
        _checkStatusOnBack(); // Restablecer incluso en caso de error
    }
  }

  Future<void> _checkStatusOnBack() async {
    // Verificar nuevamente el status después de regresar del módulo
    if (checkData != null && checkData!['status'] == 'success') {
      // Volver a enviar el scannedData
      await _verifyData();
    } else {
      // Limpiar la cache y reactivar el escáner si el status es error
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('scannedData'); // Limpiar el scannedData
       _resetScanner();// en prueba
      setState(() {
        isScanActive = true; // Reactivar el escáner
      });
    }
  }

  void _resetScanner() {
    setState(() {
      isScanActive = true; // Reactivar el escaneo
      scannedData = ''; // Limpiar datos escaneados
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla
    double screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;

    // Calcular el tamaño del cuadro central según la pantalla
    double boxSize = screenWidth * 0.6; // 60% del ancho de la pantalla

    return Scaffold(
      // appBar: AppBar(title: const Text('Escanear Check')),
      body: Stack(
        children: [
          if (isScanActive)
            MobileScanner(
              key: qrKey, // Usa la clave para reiniciar
              onDetect: (barcodeCapture) {
                if (barcodeCapture.barcodes.isNotEmpty) {
                  _onScan(barcodeCapture.barcodes.first);
                }
              },
            ),
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // 10% de los márgenes
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}