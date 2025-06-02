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

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();
  late Future<List<Document>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _documentService.fetchDocuments(widget.userId);
  }

  Future<void> _navigateToCreateDocument(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDocumentScreen(userId: widget.userId),
      ),
    );
    setState(() {
      _documentsFuture = _documentService.fetchDocuments(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
      ),
      body: FutureBuilder<List<Document>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Mensaje si no hay documentos disponibles
            return const Center(child: Text('No hay documentos disponibles.'));
          }

          final documents = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 600;
              final itemPadding = isLargeScreen ? 20.0 : 10.0;

              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];

                  return Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: itemPadding,
                      vertical: 5,
                    ),
                    color: theme.cardColor,
                    elevation: 3,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(isLargeScreen ? 16 : 8),
                      leading: Icon(
                        getStatusIcon(document.getApprovedStatus()),
                        color: getStatusColor(document.getApprovedStatus()),
                        size: isLargeScreen ? 50.0 : 40.0,
                      ),
                      title: Text(
                        'T. doc: ${translateDocumentType(document.type ?? 'Desconocido')}',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 20 : 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Estado: ',
                                style: TextStyle(color: theme.hintColor),
                              ),
                              Text(
                                getStatusSpanish(document.getApprovedStatus()),
                                style: TextStyle(
                                  color: getStatusColor(document.getApprovedStatus()),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Doc. N.º: ${getDocumentNumber(document)}',
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Navegar a la pantalla de detalles del documento
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentDetailScreen(document: document),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),


  floatingActionButton: Stack(
        children: [
          // El botón de creación de documentos
          Positioned(
            right: 10,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => _navigateToCreateDocument(context),
              child: const Icon(Icons.add),
            ),
          ),
          // El botón de confirmación solo si statusId es true
          if (widget.statusId)
            Positioned(
              right: 10,
              bottom: 85,
              child: FloatingActionButton(
                onPressed: () async {
                  // Mostrar el popup de confirmación antes de realizar la acción
                  bool? isConfirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Confirmar acción'),
                        content: const Text('¿Quieres aprobar esta solicitud?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);  // Retorna 'No'
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);  // Retorna 'Sí'
                            },
                            child: const Text('Sí'),
                          ),
                        ],
                      );
                    },
                  );

                  // Si el usuario confirma la acción, proceder con la lógica
                  if (isConfirmed == true) {
                    try {
                      // Llamar a la función updateStatusCheckScanner desde ApiServices
                      await DocumentService().updateStatusCheckScanner(widget.userId);

                      // Mostrar SnackBar de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Estado actualizado'),
                          backgroundColor: Colors.green,  // Color de fondo para éxito
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );

                      // Retroceder después de la confirmación y acción exitosa
                      Navigator.of(context).pop();  // Retrocede a la pantalla anterior

                    } catch (e) {
                      // Mostrar SnackBar de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,  // Color de fondo para error
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
                },
                backgroundColor: Colors.green,
                child: const Icon(Icons.check),
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
        return 'Cédula';
      case 'rif':
        return 'RIF';
      case 'neighborhood_association':
        return 'Asoc. Vecinos';
      case 'passport':
        return 'Pasaporte';
      default:
        return 'Desconocido';
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusSpanish(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'pending':
        return 'Pendiente';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }
}
