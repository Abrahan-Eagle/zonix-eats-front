import 'package:zonix/features/utils/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Documents/api/document_service.dart';
import '../models/document.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/utils/document_input_formatters.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img; // Importar el paquete de imagen
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

final logger = Logger();
final documentService = DocumentService();

final TextEditingController _numberCiController = TextEditingController();
final TextEditingController _taxDomicileController = TextEditingController();
final TextEditingController _rifNumberController = TextEditingController();

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
  String? _rifNumber; // RIF completo: X-NNNNNNNN-N (ej. J-12345678-9)
  String? _taxDomicile;
  DateTime? _issuedAt;
  DateTime? _expiresAt;

  /// Tipos ya registrados (CI y RIF son únicos por perfil: no mostrar en el select).
  Set<String> _registeredTypes = {};
  bool _loadingTypes = true;

  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingDocuments());
  }

  Future<void> _loadExistingDocuments() async {
    try {
      final list = await documentService.fetchMyDocuments();
      if (!mounted) return;
      setState(() {
        _registeredTypes = list.map((d) => d.type ?? '').where((t) => t.isNotEmpty).toSet();
        _loadingTypes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

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
      if (!mounted) return;
      _showCustomSnackBar(
        context,
        'Error al escanear el documento',
        AppColors.red,
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
        if (!mounted) return null;
        Navigator.of(context).pop(); // Cerrar el diálogo de carga
        return filePath; // Devolver la imagen sin compresión si es menor a 2 MB
      }

      // Decodificar la imagen
      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (!mounted) return null;
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
      if (!mounted) return null;
      Navigator.of(context).pop();

      return compressedImageFile.path;
    } catch (e) {
      // Si hay un error, cerrar el diálogo y mostrar un mensaje en el log
      debugPrint("Error al comprimir la imagen: $e");
      if (!mounted) return null;
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
        content: Text(message, style: const TextStyle(color: AppColors.white)),
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
      shadowColor: AppColors.black.withValues(alpha: 0.1),
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

    // Solo CI y RIF; cada tipo es único por perfil (no mostrar los ya registrados).
    const Map<String, String> typeTranslations = {
      'ci': 'Cédula de Identidad',
      'rif': 'RIF',
    };
    final availableEntries = typeTranslations.entries
        .where((e) => !_registeredTypes.contains(e.key))
        .toList();

    if (_loadingTypes) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Text('Cargando documentos registrados...'),
            ],
          ),
        ),
      );
    }

    if (availableEntries.isEmpty) {
      return Card(
        elevation: 2,
        shadowColor: AppColors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              const SizedBox(height: 12),
              Text(
                'Ya tienes registrados todos los documentos (Cédula y RIF). Cada uno es único por perfil.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.05),
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
            const SizedBox(height: 6),
            Text(
              'Cédula (identidad) y RIF (fiscal) se usan para verificación en pagos y métodos de pago. Uno de cada tipo por perfil.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType != null && availableEntries.any((e) => e.key == _selectedType)
                  ? _selectedType
                  : null,
              items: availableEntries
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
                  _selectedType = value ?? _selectedType;
                  _clearFields();
                  if (_selectedType == 'ci') _numberCiController.text = 'V-';
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
      _rifNumber = null;
      _taxDomicile = null;

      _issuedAt = null;
      _expiresAt = null;

      _numberCiController.clear();
      _taxDomicileController.clear();
      _rifNumberController.clear();
      if (_selectedType == 'ci') _numberCiController.text = 'V-';

      debugPrint('Campos limpiados exitosamente');
    });
  }

  Widget _buildFieldsByType() {
    switch (_selectedType) {
      case 'ci':
        return _buildCIFields();
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

  Widget _buildRIFFields() {
    return _buildFieldsCard(
      'Información de RIF',
      Icons.business,
      [
        TextFormField(
          controller: _rifNumberController,
          decoration: InputDecoration(
            labelText: 'Número RIF',
            hintText: 'Ej: J-19217553-0',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [RifVenezuelaInputFormatter()],
          onSaved: (v) => _rifNumber = v?.trim(),
          validator: (v) {
            final s = v?.trim() ?? '';
            if (s.isEmpty) return 'Requerido para RIF';
            final n = s.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
            if (!RegExp(r'^[VEJGP]\d{9}$').hasMatch(n)) {
              return 'Formato: letra (V/E/J/G/P) + 8 dígitos + 1 dígito. Ej: J-19217553-0';
            }
            return null;
          },
        ),
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
      shadowColor: AppColors.black.withValues(alpha: 0.05),
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
    return TextFormField(
      controller: _numberCiController,
      decoration: InputDecoration(
        labelText: 'Número de Cédula',
        hintText: 'Ej: V-12.345.678',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onSaved: (value) {
        final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        _numberCi = digits.isEmpty ? null : int.tryParse(digits);
      },
      inputFormatters: [
        CiVenezuelaInputFormatter(),
        LengthLimitingTextInputFormatter(12), // V-12.345.678 = 12 caracteres
      ],
      keyboardType: TextInputType.number,
      validator: (value) {
        final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isEmpty) return 'Requerido para cédula';
        if (digits.length < 6 || digits.length > 9) {
          return 'Entre 6 y 9 dígitos (ej. V-12.345.678)';
        }
        return null;
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
      shadowColor: AppColors.black.withValues(alpha: 0.05),
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
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Imagen escaneada correctamente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.green,
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
    if (_registeredTypes.length >= 2) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Botón para escanear documento
        Positioned(
          right: 0,
          bottom: 80,
          child: FloatingActionButton.extended(
            heroTag: 'document_create_scan',
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
            heroTag: 'document_create_save',
            onPressed: _saveDocument,
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
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
            rifNumber: _rifNumber?.trim().isEmpty == true ? null : _rifNumber?.trim(),
            taxDomicile: _taxDomicile,
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

            final color = _saveCounter == 3 ? AppColors.blue : AppColors.green;

            _showCustomSnackBar(context, message, color);

            Navigator.of(context)
              ..pop() // Cerrar diálogo de progreso
              ..pop(true); // Indicar éxito al retroceder
          }
        } else {
          if (!mounted) return;
          Navigator.of(context).pop(); // Cerrar diálogo de progreso
          _showCustomSnackBar(
            context,
            'La imagen frontal supera los 2 MB.',
            AppColors.orange,
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar diálogo de progreso
        logger.e('Error al guardar el documento: $e');
        _showCustomSnackBar(
          context,
          'Error al guardar el documento: $e',
          AppColors.red,
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
