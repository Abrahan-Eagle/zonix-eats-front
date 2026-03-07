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
    final surfaceBg = _surfaceBg(context);
    final primaryTextColor = AppColors.primaryText(context);
    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: Text(
          'Editar Documento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.cardBg(context),
        foregroundColor: primaryTextColor,
        iconTheme: IconThemeData(color: primaryTextColor, size: 24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: 24),
              _buildTypeCard(context),
              const SizedBox(height: 24),
              _buildFieldsByType(context),
              const SizedBox(height: 24),
              if (_frontImage != null) _buildImagePreview(context),
              const SizedBox(height: 16),
              _buildInfoNote(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  static const double _cardRadius = 12;

  Color _surfaceBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;

  Color _cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.slateBorder : AppColors.borderLight;

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Asegúrese de que todos los datos coincidan exactamente con el documento físico para evitar retrasos en la validación.',
              style: TextStyle(color: AppColors.blue.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        border: Border(top: BorderSide(color: _cardBorder(context))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton(
            onPressed: _updateDocument,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
            ),
            child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorder(context)),
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
            child: const Icon(Icons.edit, color: AppColors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Documento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifica la información del documento',
                  style: TextStyle(color: AppColors.secondaryText(context), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context) {
    final Map<String, String> typeTranslations = {
      'ci': 'Cédula de Identidad',
      'rif': 'RIF',
    };
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
          Text(
            'Tipo de Documento',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText(context)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryText(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: _cardBorder(context)),
            ),
            child: Row(
              children: [
                Icon(_getDocumentTypeIcon(_selectedType), color: AppColors.blue, size: 20),
                const SizedBox(width: 12),
                Text(
                  typeTranslations[_selectedType] ?? 'Desconocido',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        _buildDomicilioFiscalField(),
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
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryText(context),
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

  /// Domicilio fiscal: editable, valor inicial cargado desde el documento.
  Widget _buildDomicilioFiscalField() {
    return TextFormField(
      controller: _taxDomicileController,
      decoration: InputDecoration(
        labelText: 'Domicilio Fiscal',
        hintText: 'Ej: Av. Principal, Edificio X',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onSaved: (value) => _taxDomicile = value?.trim(),
      maxLines: 2,
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
              Text(
                'Documento Digitalizado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
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
                            color: AppColors.secondaryText(context).withValues(alpha: 0.2),
                            child: Center(
                              child: Icon(Icons.error_outline, size: 64, color: AppColors.secondaryText(context)),
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _scanDocument,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blue,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Cambiar imagen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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