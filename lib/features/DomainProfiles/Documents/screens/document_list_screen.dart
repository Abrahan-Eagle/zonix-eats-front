import 'package:zonix_glasses/features/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:zonix_glasses/features/DomainProfiles/Documents/api/document_service.dart';
import 'package:zonix_glasses/features/DomainProfiles/Documents/models/document.dart';
import 'package:zonix_glasses/features/DomainProfiles/Documents/screens/document_create_screen.dart';
import 'package:zonix_glasses/features/DomainProfiles/Documents/screens/document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final int userId;
  final bool statusId;
  /// Nombre del titular (ej. del perfil) para mostrarlo en el detalle. Opcional.
  final String? holderName;

  const DocumentListScreen({
    super.key,
    required this.userId,
    this.statusId = false,
    this.holderName,
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  late Future<List<Document>> _documentsFuture;
  
  // Controllers
  
  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Estados
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _documentService.fetchMyDocuments();
    
    // Inicializar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _documentsFuture = _documentService.fetchMyDocuments();
      _isRefreshing = false;
    });
  }

  Future<void> _navigateToCreateDocument(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDocumentScreen(userId: widget.userId),
      ),
    );
    _refreshDocuments();
  }

  List<Document> _filterDocuments(List<Document> documents) {
    // Mostrar todos los documentos sin filtrar
    return documents;
  }

  static const double _cardRadius = 12;
  static const double _iconBoxSize = 44;
  static const double _chipRadius = 8;

  Color _surfaceBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;

  Color _cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppColors.slateBorder : AppColors.borderLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceBg = _surfaceBg(context);
    final primaryTextColor = AppColors.primaryText(context);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: Text(
          'Mis Documentos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: primaryTextColor,
          ),
        ),
        elevation: 0,
        backgroundColor: surfaceBg,
        foregroundColor: primaryTextColor,
        iconTheme: IconThemeData(color: primaryTextColor, size: 24),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Document>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
            return _buildLoadingState(context);
          } else if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final documents = snapshot.data!;
          final filteredDocuments = _filterDocuments(documents);

          return RefreshIndicator(
            onRefresh: _refreshDocuments,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildDocumentsList(context, filteredDocuments, theme),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }



  Widget _buildDocumentsList(BuildContext context, List<Document> documents, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildDocumentCard(context, document, theme, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(BuildContext context, Document document, ThemeData theme, int index) {
    final cardBg = AppColors.cardBg(context);
    final primaryTextColor = AppColors.primaryText(context);
    final secondaryTextColor = AppColors.secondaryText(context);
    final borderColor = _cardBorder(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: cardBg,
        elevation: 0,
        shadowColor: AppColors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(_cardRadius),
          onTap: () => _navigateToDocumentDetail(document),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _iconBoxSize,
                      height: _iconBoxSize,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(_cardRadius),
                        ),
                        child: Icon(
                          _getDocumentTypeIcon(document.type ?? ''),
                          color: AppColors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              translateDocumentType(document.type ?? 'Desconocido'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getDocumentNumber(document),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: _buildStatusChip(context, document.approved),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _navigateToDocumentDetail(document),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ver detalles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.blue),
          const SizedBox(height: 16),
          Text('Cargando documentos...', style: TextStyle(color: AppColors.secondaryText(context))),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error(context).withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Error al cargar documentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: AppColors.secondaryText(context), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _refreshDocuments,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primaryTextColor = AppColors.primaryText(context);
    final secondaryTextColor = AppColors.secondaryText(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: secondaryTextColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No tienes documentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer documento para comenzar',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _navigateToCreateDocument(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar documento'),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildFloatingActionButtons() {
    return Stack(
      children: [
        Positioned(
          right: 24,
          bottom: 24,
          child: Material(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(_cardRadius),
            elevation: 2,
            shadowColor: AppColors.blue.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(_cardRadius),
              onTap: () => _navigateToCreateDocument(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Nuevo',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.statusId)
          Positioned(
            right: 24,
            bottom: 90,
            child: FloatingActionButton(
              heroTag: 'document_list_confirm',
              onPressed: _showConfirmationDialog,
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.check),
            ),
          ),
      ],
    );
  }

  void _navigateToDocumentDetail(Document document) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(
          document: document,
          userId: widget.userId,
          holderName: widget.holderName,
        ),
      ),
    );
    
    // Si se regresa de la edición, refrescar la lista
    if (result == true) {
      _refreshDocuments();
    }
  }

  Future<void> _showConfirmationDialog() async {
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar acción'),
          content: const Text('¿Quieres aprobar esta solicitud?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (isConfirmed == true) {
      await _updateStatus();
    }
  }

  Future<void> _updateStatus() async {
    try {
      await DocumentService().updateStatusCheckScanner(widget.userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Estado actualizado exitosamente'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: AppColors.white,
              onPressed: () {},
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: AppColors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Información'),
          content: const Text(
            'Aquí puedes gestionar todos tus documentos. '
            'Usa los filtros para encontrar documentos específicos '
            'y la búsqueda para localizar documentos rápidamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context, bool approved) {
    final theme = Theme.of(context);
    final isVerified = approved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.green.withValues(alpha: 0.15)
            : AppColors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.schedule,
            size: 16,
            color: isVerified ? AppColors.green : AppColors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verificado' : 'Pendiente',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isVerified ? AppColors.green : AppColors.orange,
            ),
          ),
        ],
      ),
    );
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
}
