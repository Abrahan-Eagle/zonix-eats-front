import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zonix_eats/features/DomainProfiles/Documents/api/document_service.dart';
import 'package:zonix_eats/features/DomainProfiles/Documents/widgets/mobile_scanner_xz.dart';
import '../models/document.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img; // Importar el paquete de imagen
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter/scheduler.dart';


final logger = Logger();
final documentService = DocumentService();

final TextEditingController _numberCiController = TextEditingController();
final TextEditingController _taxDomicileController = TextEditingController();
final TextEditingController _communeRegisterController = TextEditingController();
final TextEditingController _communityRifController = TextEditingController();
final TextEditingController _rifUrlController = TextEditingController();
final TextEditingController _receiptNController = TextEditingController();
final TextEditingController _skyController = TextEditingController();



class CreateDocumentScreen extends StatefulWidget {
  final int userId;

  const CreateDocumentScreen({super.key, required this.userId});

  @override
  CreateDocumentScreenState createState() => CreateDocumentScreenState();
}

class CreateDocumentScreenState extends State<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedType;
  int? _numberCi;
  String? _frontImage;
  String? _rifUrl;
  String? _taxDomicile;
  int? _sky;
  String? _communeRegister; // Campo específico para 'neighborhood_association'
  String? _communityRif;
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  int? _receiptN;

  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    ValueChanged<DateTime?> onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateSelected(picked);
  }

  // Función para escanear un documento y luego obtener la imagen escaneada
  Future<void> _scanDocument() async {
    try {
      setState(() {
        _result = null;
      });

      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.full,
          isGalleryImport: false,
          pageLimit: 1,
        ),
      );

      _result = await _documentScanner?.scanDocument();
      if (_result?.images.isNotEmpty == true) {
        // Suponiendo que _result.images es una lista de File o algo que contiene la imagen escaneada
        final scannedImage = _result!.images.first;
        final compressedImage = await _compressImage(
          scannedImage,
        ); // Obtén el path de la imagen
        setState(() {
          _frontImage = compressedImage;
        });
      }
    } catch (e) {
      debugPrint("Error al escanear el documento: $e");
      _showCustomSnackBar(
        context,
        'Error al escanear el documento',
        Colors.red,
      );
    }
  }

  Future<String?> _compressImage(String filePath) async {
    try {
      // Mostrar el diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false, // Impide cerrar el diálogo tocando fuera
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final imageFile = File(filePath);

      // Verificar si la imagen ya es suficientemente pequeña (menor a 2 MB)
      if (await imageFile.length() <= 2 * 1024 * 1024) {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga
        return filePath; // Devolver la imagen sin compresión si es menor a 2 MB
      }

      // Decodificar la imagen
      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga
        throw Exception("No se pudo decodificar la imagen.");
      }

      String extension = filePath.split('.').last.toLowerCase();
      int quality = 85;
      List<int> compressedBytes;

      // Comprimir la imagen según el tipo (PNG o JPG)
      if (extension == 'png') {
        compressedBytes = img.encodePng(originalImage, level: 6);
      } else {
        compressedBytes = img.encodeJpg(originalImage, quality: quality);

        // Intentar reducir la calidad si la imagen es mayor a 2 MB
        while (compressedBytes.length > 2 * 1024 * 1024 && quality > 10) {
          quality -= 5;
          compressedBytes = img.encodeJpg(originalImage, quality: quality);
        }
      }

      // Guardar la imagen comprimida
      final compressedImageFile = await File(
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
      ).writeAsBytes(compressedBytes);

      debugPrint("Imagen comprimida guardada en: ${compressedImageFile.path}");

      // Cerrar el diálogo de carga después de guardar la imagen
      Navigator.of(context).pop();

      return compressedImageFile.path;
    } catch (e) {
      // Si hay un error, cerrar el diálogo y mostrar un mensaje en el log
      debugPrint("Error al comprimir la imagen: $e");
      Navigator.of(context).pop(); // Cerrar el diálogo de carga
      throw Exception("Error al comprimir la imagen: $e");
    }
  }

  void _showCustomSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Documento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTypeDropdown(),
              const SizedBox(height: 16.0),
              if (_selectedType != null) _buildFieldsByType(),
              const SizedBox(height: 16.0),
              if (_frontImage != null) ...[
                const SizedBox(height: 16.0),
                // Tarjeta para mostrar la imagen escaneada
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  margin: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        File(_frontImage!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

     

                Builder(
                  builder: (BuildContext context) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      _showCustomSnackBar(
                        context,
                        'Imagen escaneada',
                        Colors.green,
                      );
                    });
                    return const SizedBox.shrink(); // Devuelve un widget vacío
                  },
                ),




              ],
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Botón para escanear documento
          Positioned(
            right: 10,
            bottom: 85,
            child: FloatingActionButton(
              onPressed: _scanDocument,
              backgroundColor: Colors.orange,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera, size: 20),
                  Text(
                    'Escanear',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // Botón para guardar documento
          Positioned(
            right: 10,
            bottom: 11,
            child: FloatingActionButton(
              onPressed: _saveDocument,
              backgroundColor: Colors.green,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 20),
                  Text(
                    'Guardar',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTypeDropdown() {
    final Map<String, String> typeTranslations = {
      'ci': 'Cédula de Identidad',
      'passport': 'Pasaporte',
      'rif': 'RIF',
      'neighborhood_association': 'Asociación de Vecinos',
    };

    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: typeTranslations.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
 

onChanged: (value) {
  setState(() {
    _selectedType = value;
    _clearFields(); // Limpiar los campos
  });
},

    decoration: const InputDecoration(labelText: 'Tipo de Documento'),
    validator: (value) => value == null ? 'Seleccione un tipo' : null,
  );
}

void _clearFields() {
  debugPrint('Limpieza de campos iniciada');
  setState(() {
    // Limpiar las variables
    _numberCi = null;
    _frontImage = null;
    _rifUrl = null;
    _taxDomicile = null;
    _sky = null;
    _communeRegister = null;
    _communityRif = null;
    _issuedAt = null;
    _expiresAt = null;
    _receiptN = null;

    // Limpiar los controladores
    _numberCiController.clear();
    _taxDomicileController.clear();
    _communeRegisterController.clear();
    _communityRifController.clear();
    _rifUrlController.clear();
    _receiptNController.clear();
    _skyController.clear();

    debugPrint('Campos limpiados exitosamente');
  });
}


  Widget _buildFieldsByType() {
    switch (_selectedType) {
      case 'ci':
        return _buildCIFields();
      case 'passport':
        return _buildPassportFields();
      case 'rif':
        return _buildRIFFields();
      case 'neighborhood_association':
        return _buildAssociationFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCIFields() {
    return Column(
      children: [
        _buildNumberField(),
        const SizedBox(height: 16.0),
        //_buildImageRow('Imagen Frontal'),
        // _showCapturedImages(), // Mostrar imágenes capturadas
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildPassportFields() {
    return Column(
      children: [
        _buildNumberField(),
        _buildReceiptNField(),
        const SizedBox(height: 16.0),
        //_buildImageRow('Imagen Frontal'),
        // _showCapturedImages(),
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildRIFFields() {
    return Column(
      children: [
        _buildSkyField(),
        _buildReceiptNField(),
        _buildQRScannerField(), // Reemplaza el campo de URL RIF por el botón
        _buildTextField('Domicilio Fiscal', (value) => _taxDomicile = value),
        const SizedBox(height: 16.0),
        //_buildImageRow('Imagen Frontal'),
        // _showCapturedImages(),
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildAssociationFields() {
    return Column(
      children: [
        _buildTextField('Registro Comunal', (value) => _communeRegister = value,),
        _buildTextField('RIF Comunitario', (value) => _communityRif = value),
        _buildTextField('Domicilio Fiscal', (value) => _taxDomicile = value),
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildQRScannerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text('URL RIF', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16.0),
        ElevatedButton.icon(
          onPressed: _scanQRCode,
          icon: const Icon(
            Icons.qr_code_scanner,
            size: 30,
          ), // Aumenta el tamaño del icono
          label: const Text(
            'Escanear QR RIF',
            style: TextStyle(fontSize: 18), // Aumenta el tamaño del texto
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ), // Aumenta el padding
            minimumSize: const Size(
              double.infinity,
              60,
            ), // Aumenta la altura mínima del botón
          ),
        ),
        if (_rifUrl != null) ...[
          const SizedBox(height: 16.0),
          Text('URL escaneada: $_rifUrl'),
        ],
      ],
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        _buildDateField(
          'Fecha de Emisión',
          _issuedAt,
          (date) => _issuedAt = date,
        ),
        const SizedBox(height: 16.0),
        _buildDateField(
          'Fecha de Expiración',
          _expiresAt,
          (date) => _expiresAt = date,
        ),
      ],
    );
  }

Widget _buildNumberField() {
  return TextFormField(
    controller: _numberCiController, // Asegúrate de vincular el controlador
    decoration: const InputDecoration(labelText: 'N° Cédula'),
    onSaved: (value) => _numberCi = int.tryParse(value ?? ''),
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8), // Limitar a 8 caracteres
    ],
    keyboardType: TextInputType.number,
    validator: (value) {
      if (value == null || value.length < 7 || value.length > 8) {
        return 'Por favor, ingrese un número entre 7 y 8 dígitos';
      }
      return null;
    },
  );
}



  Widget _buildReceiptNField() {
  return TextFormField(
    controller: _receiptNController,
    decoration: const InputDecoration(labelText: 'N° Comprobante'),
    onSaved: (value) => _receiptN = int.tryParse(value ?? ''),
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    keyboardType: TextInputType.number,
  );
}

// Widget _buildSkyField() {
//   return TextFormField(
//     controller: _skyController,
//     decoration: const InputDecoration(labelText: 'N° Sky'),
//     onSaved: (value) => _sky = int.tryParse(value ?? ''),
//     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//     keyboardType: TextInputType.number,
//   );
// }


Widget _buildSkyField() {
  return TextFormField(
    controller: _skyController,
    decoration: const InputDecoration(
      labelText: 'N° Sky',
      errorText: null, // Para mostrar el mensaje de error personalizado
    ),
    onSaved: (value) => _sky = int.tryParse(value ?? ''),
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    keyboardType: TextInputType.number,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Este campo es obligatorio';
      }
      // Verificar si el número tiene entre 9 y 11 dígitos
      if (value.length < 9 || value.length > 11) {
        return 'El número debe tener entre 9 y 11 dígitos';
      }
      return null; // Validación correcta
    },
  );
}


  Widget _buildTextField(
    String label,
    FormFieldSetter<String> onSaved, {
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onSaved: onSaved,
      inputFormatters: inputFormatters, // Aplicar inputFormatters
      keyboardType: keyboardType, // Establecer el tipo de teclado
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onDateSelected,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed:
              () => _selectDate(
                context,
                (picked) => setState(() => onDateSelected(picked)),
              ),
        ),
      ),
      readOnly: true,
      validator: (value) => date == null ? 'Seleccione una fecha' : null,
      controller: TextEditingController(
        text: date != null ? '${date.toLocal()}'.split(' ')[0] : '',
      ),
    );
  }

  File? _getFileFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    // Comprobación del resultado
    if (result != null && result is String) {
      setState(() {
        _rifUrl = result; // Asegúrate de que 'result' sea una cadena no nula
      });
    } else {
      // Manejo de error si el resultado es nulo o no es una cadena
      logger.e('Escaneo cancelado o fallido.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escaneo cancelado o fallido.')),
      );
    }
  }

  int _saveCounter = 0; // Contador para guardar documentos, inicia en 0

//   Future<void> _saveDocument() async {
//   if (_formKey.currentState!.validate()) {
//     _formKey.currentState!.save();
//     try {
//       // Mostrar un diálogo con indicador de progreso
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return const Center(child: CircularProgressIndicator());
//         },
//       );

//       // Verificar el tamaño de la imagen antes de enviarla
//       if (_frontImage != null && await _isImageSizeValid(_frontImage)) {
//         Document document = Document(
//           id: 0,
//           type: _selectedType,
//           numberCi: _numberCi?.toString(),
//           receiptN: _receiptN,
//           rifUrl: _rifUrl,
//           taxDomicile: _taxDomicile,
//           sky: _sky,
//           communeRegister: _communeRegister,
//           communityRif: _communityRif,
//           frontImage: _frontImage,
//           issuedAt: _issuedAt,
//           expiresAt: _expiresAt,
//           approved: false,
//           status: true,
//         );

//         await documentService.createDocument(
//           document,
//           widget.userId,
//           frontImageFile: _getFileFromPath(document.frontImage),
//         );

//         if (mounted) {
//           setState(() {
//             _saveCounter++;
//           });

//           // Mensaje según contador
//           if (_saveCounter == 3) {
//             Provider.of<UserProvider>(
//               context,
//               listen: false,
//             ).setDocumentCreated(true);
//             _showCustomSnackBar(
//               context,
//               'Límite alcanzado. Puedes avanzar al siguiente paso.',
//               Colors.blue,
//             );
//           } else {
//             _showCustomSnackBar(
//               context,
//               'Documento guardado exitosamente',
//               Colors.green,
//             );
//           }

//           // Retroceder a la ventana anterior después de cerrar el diálogo
//           Navigator.of(context)
//             ..pop() // Cierra el diálogo
//             ..pop(); // Retrocede a la ventana anterior
//         }
//       } else {
//         Navigator.of(context).pop(); // Cerrar el diálogo modal
//         _showCustomSnackBar(
//           context,
//           'La imagen frontal supera los 2 MB.',
//           Colors.orange,
//         );
//       }
//     } catch (e) {
//       Navigator.of(context).pop(); // Cerrar el diálogo modal
//       logger.e('Error al guardar el documento: $e');
//       _showCustomSnackBar(
//         context,
//         'Error al guardar el documento: $e',
//         Colors.red,
//       );
//     }
//   }
// }

Future<void> _saveDocument() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    try {
      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Verificar tamaño de la imagen
      if (_frontImage != null && await _isImageSizeValid(_frontImage)) {
        Document document = Document(
          id: 0,
          type: _selectedType,
          numberCi: _numberCi?.toString(),
          receiptN: _receiptN,
          rifUrl: _rifUrl,
          taxDomicile: _taxDomicile,
          sky: _sky,
          communeRegister: _communeRegister,
          communityRif: _communityRif,
          frontImage: _frontImage,
          issuedAt: _issuedAt,
          expiresAt: _expiresAt,
          approved: false,
          status: true,
        );

        await documentService.createDocument(
          document,
          widget.userId,
          frontImageFile: _getFileFromPath(document.frontImage),
        );

        if (mounted) {
          setState(() {
            _saveCounter++;
          });

          final message = _saveCounter == 3
              ? 'Límite alcanzado. Puedes avanzar al siguiente paso.'
              : 'Documento guardado exitosamente.';

          final color = _saveCounter == 3 ? Colors.blue : Colors.green;

          _showCustomSnackBar(context, message, color);

          Navigator.of(context)
            ..pop() // Cerrar diálogo de progreso
            ..pop(true); // Indicar éxito al retroceder
        }
      } else {
        Navigator.of(context).pop(); // Cerrar diálogo de progreso
        _showCustomSnackBar(
          context,
          'La imagen frontal supera los 2 MB.',
          Colors.orange,
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar diálogo de progreso
      logger.e('Error al guardar el documento: $e');
      _showCustomSnackBar(
        context,
        'Error al guardar el documento: $e',
        Colors.red,
      );
    }
  }
}




  Future<bool> _isImageSizeValid(String? path) async {
    if (path == null) return false;
    final file = File(path);
    final sizeInBytes = await file.length();
    return sizeInBytes <= 2048 * 1024; // 2048 KB
  }
}
