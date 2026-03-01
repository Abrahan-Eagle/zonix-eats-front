import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Documents/api/document_service.dart';
import 'package:zonix/features/DomainProfiles/Documents/models/document.dart';
import 'package:zonix/features/DomainProfiles/Documents/screens/document_create_screen.dart';
import 'package:zonix/features/DomainProfiles/Documents/screens/document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final int userId;
  final bool statusId;

  const DocumentListScreen({super.key, required this.userId, this.statusId = false});

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
    _documentsFuture = _documentService.fetchDocuments(widget.userId);
    
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
      _documentsFuture = _documentService.fetchDocuments(widget.userId);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Mis Documentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
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
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final documents = snapshot.data!;
          final filteredDocuments = _filterDocuments(documents);

          return RefreshIndicator(
            onRefresh: _refreshDocuments,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildDocumentsList(filteredDocuments, theme),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }



  Widget _buildDocumentsList(List<Document> documents, ThemeData theme) {
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
                child: _buildDocumentCard(document, theme, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(Document document, ThemeData theme, int index) {
    
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDocumentDetail(document),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con tipo y estado
                Row(
                  children: [
                    // Icono del tipo de documento
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getDocumentTypeIcon(document.type ?? ''),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Información principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translateDocumentType(document.type ?? 'Desconocido'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nº ${getDocumentNumber(document)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    

                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Información adicional
                if (document.issuedAt != null || document.expiresAt != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (document.issuedAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Emitido: ${_formatDate(document.issuedAt!)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (document.expiresAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Vence: ${_formatDate(document.expiresAt!)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToDocumentDetail(document),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Ver detalles'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando documentos...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar documentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshDocuments,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes documentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu primer documento para comenzar',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateDocument(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar documento'),
          ),
        ],
      ),
    );
  }



  Widget _buildFloatingActionButtons() {
    return Stack(
      children: [
        // Botón de creación de documentos
        Positioned(
          right: 10,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'document_list_new',
            onPressed: () => _navigateToCreateDocument(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        
        // Botón de confirmación solo si statusId es true
        if (widget.statusId)
          Positioned(
            right: 10,
            bottom: 85,
            child: FloatingActionButton(
              heroTag: 'document_list_confirm',
              onPressed: _showConfirmationDialog,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
        builder: (context) => DocumentDetailScreen(document: document),
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
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
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
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
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

  // Métodos auxiliares
  String getDocumentNumber(Document document) {
    switch (document.type) {
      case 'ci':
        return document.numberCi ?? 'N/A';
      case 'passport':
        return document.receiptN?.toString() ?? 'N/A';
      case 'rif':
        return document.sky?.toString() ?? 'N/A';
      case 'neighborhood_association':
        return document.communeRegister ?? 'N/A';
      default:
        return 'Desconocido';
    }
  }

  String translateDocumentType(String type) {
    switch (type) {
      case 'ci':
        return 'Cédula de Identidad';
      case 'rif':
        return 'RIF';
      case 'neighborhood_association':
        return 'Asociación de Vecinos';
      case 'passport':
        return 'Pasaporte';
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
      case 'neighborhood_association':
        return Icons.people;
      case 'passport':
        return Icons.flight_takeoff;
      default:
        return Icons.description;
    }
  }



  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
