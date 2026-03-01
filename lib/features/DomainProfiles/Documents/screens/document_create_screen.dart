import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Documents/api/document_service.dart';
import 'package:zonix/features/DomainProfiles/Documents/widgets/mobile_scanner_xz.dart';
import '../models/document.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img; // Importar el paquete de imagen
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Crear Documento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con información
              _buildHeaderCard(context),
              
              const SizedBox(height: 24),
              
              // Tipo de documento
              _buildTypeDropdown(),
              
              const SizedBox(height: 24),
              
              // Campos específicos según el tipo
              if (_selectedType != null) _buildFieldsByType(),
              
              const SizedBox(height: 24),
              
              // Imagen escaneada
              if (_frontImage != null) _buildImagePreview(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo Documento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Agrega un nuevo documento a tu perfil',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Map<String, String> typeTranslations = {
      'ci': 'Cédula de Identidad',
      'passport': 'Pasaporte',
      'rif': 'RIF',
    };

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Documento',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: typeTranslations.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(
                            _getDocumentTypeIcon(entry.key),
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(entry.value),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _clearFields(); // Limpiar los campos
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) => value == null ? 'Seleccione un tipo' : null,
            ),
          ],
        ),
      ),
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

      _issuedAt = null;
      _expiresAt = null;
      _receiptN = null;

      // Limpiar los controladores
      _numberCiController.clear();
      _taxDomicileController.clear();

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

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCIFields() {
    return _buildFieldsCard(
      'Información de Cédula',
      Icons.badge,
      [
        _buildNumberField(),
        const SizedBox(height: 20),
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildPassportFields() {
    return _buildFieldsCard(
      'Información de Pasaporte',
      Icons.flight_takeoff,
      [
        _buildReceiptNField(),
        const SizedBox(height: 20),
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildRIFFields() {
    return _buildFieldsCard(
      'Información de RIF',
      Icons.business,
      [
        _buildSkyField(),
        const SizedBox(height: 20),
        _buildReceiptNField(),
        const SizedBox(height: 20),
        _buildQRScannerField(),
        const SizedBox(height: 20),
        _buildTextField('Domicilio Fiscal', (value) => _taxDomicile = value),
        const SizedBox(height: 20),
        _buildCommonFields(),
      ],
    );
  }



  Widget _buildFieldsCard(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildQRScannerField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR RIF',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _scanQRCode,
            icon: const Icon(Icons.qr_code_scanner, size: 24),
            label: const Text(
              'Escanear QR RIF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_rifUrl != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR escaneado correctamente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        const SizedBox(height: 20),
        _buildDateField(
          'Fecha de Expiración',
          _expiresAt,
          (date) => _expiresAt = date,
        ),
      ],
    );
  }

  Widget _buildNumberField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _numberCiController, // Asegúrate de vincular el controlador
      decoration: InputDecoration(
        labelText: 'Número de Documento',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _receiptNController,
      decoration: InputDecoration(
        labelText: 'Número de Comprobante',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onSaved: (value) => _receiptN = int.tryParse(value ?? ''),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildSkyField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _skyController,
      decoration: InputDecoration(
        labelText: 'Número Sky',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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

  Widget _buildImagePreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Imagen del Documento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.file(
                  File(_frontImage!),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Imagen escaneada correctamente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        // Botón para escanear documento
        Positioned(
          right: 0,
          bottom: 80,
          child: FloatingActionButton.extended(
            onPressed: _scanDocument,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Escanear'),
          ),
        ),
        // Botón para guardar documento
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton.extended(
            onPressed: _saveDocument,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ),
      ],
    );
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'ci':
        return Icons.badge;
      case 'passport':
        return Icons.flight_takeoff;
      case 'rif':
        return Icons.business;

      default:
        return Icons.description;
    }
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
            communeRegister: null,
            communityRif: null,
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
