import 'package:zonix/features/utils/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Documents/api/document_service.dart';
import '../models/document.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/utils/document_input_formatters.dart';
import 'package:zonix/features/utils/rif_formatter.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import 'package:zonix/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

final logger = Logger();
final documentService = DocumentService();

class DocumentEditScreen extends StatefulWidget {
  final Document document;
  final int? userId;

  const DocumentEditScreen({
    super.key, 
    required this.document,
    this.userId,
  });

  @override
  DocumentEditScreenState createState() => DocumentEditScreenState();
}

class DocumentEditScreenState extends State<DocumentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType;
  int? _numberCi;
  String? _frontImage;
  String? _rifNumber;
  String? _taxDomicile;
  DateTime? _issuedAt;
  DateTime? _expiresAt;

  // Controllers
  final TextEditingController _numberCiController = TextEditingController();
  final TextEditingController _rifNumberController = TextEditingController();
  final TextEditingController _taxDomicileController = TextEditingController();

  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  @override
  void initState() {
    super.initState();
    _initializeDocumentData();
  }

  void _initializeDocumentData() {
    _selectedType = widget.document.type ?? 'ci';
    _numberCi = int.tryParse(widget.document.numberCi ?? '');
    _frontImage = widget.document.frontImage;
    _rifNumber = widget.document.rifNumber;
    _taxDomicile = widget.document.taxDomicile;
    _issuedAt = widget.document.issuedAt;
    _expiresAt = widget.document.expiresAt;

    _numberCiController.text = formatCiForDisplay(_numberCi);
    _rifNumberController.text = formatRifDisplay(_rifNumber) ?? _rifNumber ?? '';
    _taxDomicileController.text = _taxDomicile ?? '';
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
        final scannedImage = _result!.images.first;
        final compressedImage = await _compressImage(scannedImage);
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final imageFile = File(filePath);

      if (await imageFile.length() <= 2 * 1024 * 1024) {
        if (!mounted) return null;
        Navigator.of(context).pop();
        return filePath;
      }

      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (!mounted) return null;
      if (originalImage == null) {
        Navigator.of(context).pop();
        throw Exception("No se pudo decodificar la imagen.");
      }

      String extension = filePath.split('.').last.toLowerCase();
      int quality = 85;
      List<int> compressedBytes;

      if (extension == 'png') {
        compressedBytes = img.encodePng(originalImage, level: 6);
      } else {
        compressedBytes = img.encodeJpg(originalImage, quality: quality);

        while (compressedBytes.length > 2 * 1024 * 1024 && quality > 10) {
          quality -= 5;
          compressedBytes = img.encodeJpg(originalImage, quality: quality);
        }
      }

      final compressedImageFile = await File(
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
      ).writeAsBytes(compressedBytes);

      debugPrint("Imagen comprimida guardada en: ${compressedImageFile.path}");

      if (!mounted) return null;
      Navigator.of(context).pop();

      return compressedImageFile.path;
    } catch (e) {
      debugPrint("Error al comprimir la imagen: $e");
      if (!mounted) return null;
      Navigator.of(context).pop();
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
          'Editar Documento',
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
              
              // Tipo de documento (no editable)
              _buildTypeCard(),
              
              const SizedBox(height: 24),
              
              // Campos específicos según el tipo
              _buildFieldsByType(),
              
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
              AppColors.orange.withValues(alpha: 0.1),
              AppColors.orange.withValues(alpha: 0.05),
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
                    color: AppColors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Documento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Modifica la información del documento',
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

  Widget _buildTypeCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Map<String, String> typeTranslations = {
      // Solo CI y RIF según regla de negocio
      'ci': 'Cédula de Identidad',
      'rif': 'RIF',
    };

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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDocumentTypeIcon(_selectedType),
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    typeTranslations[_selectedType] ?? 'Desconocido',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
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
            if (_selectedType != 'rif') return null;
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
        LengthLimitingTextInputFormatter(12),
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
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
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
          onPressed: () => _selectDate(
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
                child: _frontImage!.startsWith('http')
                    ? Image.network(
                        _frontImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.gray,
                            child: const Center(
                              child: Icon(Icons.error_outline, size: 64, color: AppColors.gray),
                            ),
                          );
                        },
                      )
                    : Image.file(
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
                    'Imagen disponible',
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        // Botón para escanear documento
        Positioned(
          right: 0,
          bottom: 80,
          child: FloatingActionButton.extended(
            heroTag: 'document_edit_scan',
            onPressed: _scanDocument,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Escanear'),
          ),
        ),
        // Botón para guardar cambios
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton.extended(
            heroTag: 'document_edit_save',
            onPressed: _updateDocument,
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
    if (path.startsWith('http')) return null; // Skip network images
    return File(path);
  }

  Future<void> _updateDocument() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        final userId = widget.userId ?? Provider.of<UserProvider>(context, listen: false).userId;

        // Create updated document
        Document updatedDocument = Document(
          id: widget.document.id,
          type: _selectedType,
          numberCi: _numberCi?.toString(),
          rifNumber: _rifNumber?.trim().isEmpty == true ? null : _rifNumber?.trim(),
          taxDomicile: _taxDomicile,
          frontImage: _frontImage,
          issuedAt: _issuedAt,
          expiresAt: _expiresAt,
          approved: widget.document.approved,
          status: widget.document.status,
        );

        await documentService.updateDocument(
          updatedDocument,
          userId,
          frontImageFile: _getFileFromPath(updatedDocument.frontImage),
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showCustomSnackBar(
            context,
            'Documento actualizado exitosamente',
            AppColors.green,
          );
          Navigator.of(context).pop(true); // Return to previous screen with success
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        logger.e('Error al actualizar el documento: $e');
        _showCustomSnackBar(
          context,
          'Error al actualizar el documento: $e',
          AppColors.red,
        );
      }
    }
  }
} 