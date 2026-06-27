import 'package:zonix_glasses/features/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:zonix_glasses/features/DomainProfiles/Documents/models/document.dart';
import 'document_edit_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final Document document;
  /// user_id del dueño del perfil (para DocumentEditScreen y servicios que usan user_id).
  final int userId;
  /// Nombre del titular del documento (ej. del perfil). Si no se pasa, no se muestra la fila en la card de información.
  final String? holderName;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.userId,
    this.holderName,
  });

  static const double _cardRadius = 12;

  Color _surfaceBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;

  Color _cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.slateBorder : AppColors.borderLight;

  @override
  Widget build(BuildContext context) {
    final surfaceBg = _surfaceBg(context);
    final primaryTextColor = AppColors.primaryText(context);
    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: Text(
          document.type == 'rif' ? 'Detalle del RIF' : 'Detalle del Documento',
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
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.accentButton(context)),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: _buildDocumentDetails(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildDocumentDetails(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          _buildDocumentInfoCard(context),
          if (document.type == 'rif' && document.taxDomicile != null && document.taxDomicile!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSectionTitle(context, 'Domicilio Fiscal'),
            const SizedBox(height: 6),
            _buildTaxDomicileCard(context),
          ],
          if (document.issuedAt != null || document.expiresAt != null) ...[
            const SizedBox(height: 12),
            _buildSectionTitle(context, 'Fechas'),
            const SizedBox(height: 6),
            _buildDatesCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText(context),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final hasImage = document.frontImage != null && document.frontImage!.isNotEmpty;
    final theme = Theme.of(context);
    final cardBg = AppColors.cardBg(context);
    final primaryTextColor = AppColors.primaryText(context);
    final secondaryTextColor = AppColors.secondaryText(context);
    final borderColor = _cardBorder(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: AppColors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            GestureDetector(
              onTap: () => _showImageDialog(context, document.frontImage!),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  document.frontImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: secondaryTextColor.withValues(alpha: 0.2),
                    child: Icon(Icons.broken_image_outlined, size: 48, color: secondaryTextColor),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.type == 'rif' ? 'RIF Principal' : 'Cédula de Identidad',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  getDocumentNumber(document),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(context),
                    if (hasImage)
                      TextButton(
                        onPressed: () => _showImageDialog(context, document.frontImage!),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.blue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Ver documento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final isVerified = document.approved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.green.withValues(alpha: 0.15)
            : AppColors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified ? AppColors.green : AppColors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.schedule,
            size: 16,
            color: isVerified ? AppColors.green : AppColors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            isVerified ? 'Verificado' : 'Pendiente',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isVerified ? AppColors.green : AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoCard(BuildContext context) {
    return _buildWhiteCard(
      context,
      child: Column(
        children: [
          _buildInfoRow(context, 'Tipo de documento', translateDocumentType(document.type ?? 'Desconocido')),
          if (holderName != null && holderName!.trim().isNotEmpty) ...[
            _buildInfoRowDivider(context),
            _buildInfoRow(context, 'Nombre del titular', holderName!.trim()),
          ],
          _buildInfoRowDivider(context),
          _buildInfoRow(
            context,
            'Descripción',
            document.type == 'ci' ? 'Documento Nacional de Identidad' : 'Registro de Información Fiscal',
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorder(context)),
        boxShadow: const [BoxShadow(color: AppColors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.secondaryText(context), fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowDivider(BuildContext context) {
    return Divider(height: 1, color: _cardBorder(context));
  }

  Widget _buildDatesCard(BuildContext context) {
    final secondaryTextColor = AppColors.secondaryText(context);
    final primaryTextColor = AppColors.primaryText(context);
    return _buildWhiteCard(
      context,
      child: Column(
        children: [
          if (document.issuedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: secondaryTextColor),
                  const SizedBox(width: 12),
                  Text('Emisión', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  const Spacer(),
                  Text(
                    _formatDate(document.issuedAt!),
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (document.issuedAt != null && document.expiresAt != null)
            Divider(height: 1, color: _cardBorder(context)),
          if (document.expiresAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.event_busy, size: 20, color: secondaryTextColor),
                  const SizedBox(width: 12),
                  Text('Vencimiento', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  const Spacer(),
                  Text(
                    _formatDate(document.expiresAt!),
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaxDomicileCard(BuildContext context) {
    return _buildWhiteCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.taxDomicile ?? '',
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (document.taxDomicile != null && document.taxDomicile!.isNotEmpty)
            const SizedBox(height: 4),
          if (document.taxDomicile != null && document.taxDomicile!.isNotEmpty)
            Text(
              'Domicilio registrado en el RIF',
              style: TextStyle(color: AppColors.secondaryText(context), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: _cardBorder(context))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _navigateToEdit(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
            ),
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Editar Información', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentEditScreen(document: document, userId: userId),
      ),
    );
    if (!context.mounted) return;
    // Si la edición fue exitosa, refrescar los datos
    if (result == true) {
      // Pasar el resultado hacia atrás para que la lista se refresque
      Navigator.of(context).pop(true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String translateDocumentType(String type) {
    switch (type) {
      case 'ci':
        return 'Cédula de Identidad';
      case 'rif':
        return 'RIF';
      default:
        return 'Documento';
    }
  }

  String getDocumentNumber(Document document) {
    switch (document.type) {
      case 'ci':
        return document.numberCi ?? 'N/A';
      case 'rif':
        return document.formattedRifNumber ?? document.rifNumber?.trim() ?? 'N/A';
      default:
        return 'N/A';
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imagen disponible'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: _cardBorder(context))),
                ),
                child: Row(
                  children: [
                    Text(
                      'Imagen del Documento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppColors.primaryText(context)),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 400,
                  errorBuilder: (ctx, error, stackTrace) {
                    final secondary = AppColors.secondaryText(ctx);
                    return Container(
                      width: double.infinity,
                      height: 400,
                      color: secondary.withValues(alpha: 0.2),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: secondary),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar la imagen',
                              style: TextStyle(color: secondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
