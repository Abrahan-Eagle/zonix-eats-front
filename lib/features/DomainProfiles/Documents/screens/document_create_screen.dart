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
    final surfaceBg = _surfaceBg(context);
    final primaryTextColor = AppColors.primaryText(context);
    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: Text(
          'Crear Documento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        elevation: 0,
        backgroundColor: surfaceBg,
        foregroundColor: primaryTextColor,
        iconTheme: IconThemeData(color: primaryTextColor, size: 24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: 24),
              _buildTypeDropdown(),
              const SizedBox(height: 24),
              if (_selectedType != null) _buildFieldsByType(context),
              const SizedBox(height: 24),
              if (_frontImage != null) _buildImagePreview(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomSheet: _buildFloatingActionButtons(context),
    );
  }

  static const double _cardRadius = 12;

  Color _surfaceBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;

  Color _cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.slateBorder : AppColors.borderLight;

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorder(context)),
        boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            child: const Icon(Icons.description, color: AppColors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo Documento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega un nuevo documento a tu perfil',
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    // Solo CI y RIF; cada tipo es único por perfil (no mostrar los ya registrados).
    const Map<String, String> typeTranslations = {
      'ci': 'Cédula de Identidad',
      'rif': 'RIF',
    };
    final availableEntries = typeTranslations.entries
        .where((e) => !_registeredTypes.contains(e.key))
        .toList();

    final cardBg = AppColors.cardBg(context);
    final primaryTextColor = AppColors.primaryText(context);
    final secondaryTextColor = AppColors.secondaryText(context);
    final borderColor = _cardBorder(context);

    if (_loadingTypes) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Cargando documentos registrados...',
                style: TextStyle(color: secondaryTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (availableEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Documento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Ya tienes registrados todos los documentos (Cédula y RIF). Cada uno es único por perfil.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Documento',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Cédula (identidad) y RIF (fiscal) se usan para verificación en pagos. Uno de cada tipo por perfil.',
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getDocumentTypeIcon(entry.key), color: AppColors.blue, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_cardRadius)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: AppColors.cardBg(context),
            ),
            validator: (value) => value == null ? 'Seleccione un tipo' : null,
          ),
        ],
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

  Widget _buildFieldsByType(BuildContext context) {
    switch (_selectedType) {
      case 'ci':
        return _buildCIFields(context);
      case 'rif':
        return _buildRIFFields(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCIFields(BuildContext context) {
    return _buildFieldsCard(
      context,
      'Información de Cédula',
      Icons.badge,
      [
        _buildNumberField(),
        const SizedBox(height: 20),
        _buildCommonFields(),
      ],
    );
  }

  Widget _buildRIFFields(BuildContext context) {
    return _buildFieldsCard(
      context,
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



  Widget _buildFieldsCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryText(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
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

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo, color: AppColors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Imagen del Documento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryText(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
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
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    if (_registeredTypes.length >= 2) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _scanDocument,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
              ),
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Escanear documento'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _saveDocument,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
              ),
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
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
