import 'package:flutter/material.dart';
import '../services/export_service.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({Key? key}) : super(key: key);

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  List<Map<String, dynamic>> exportHistory = [];
  bool isLoading = true;
  bool isRequestingExport = false;

  final List<String> availableDataTypes = [
    'profile',
    'orders',
    'activity',
    'reviews',
    'addresses',
    'notifications',
  ];

  final List<String> availableFormats = [
    'json',
    'csv',
    'pdf',
  ];

  Set<String> selectedDataTypes = {'profile', 'orders', 'activity'};
  String selectedFormat = 'json';

  @override
  void initState() {
    super.initState();
    _loadExportHistory();
  }

  Future<void> _loadExportHistory() async {
    try {
      setState(() {
        isLoading = true;
      });

      final history = await ExportService.getExportHistory();
      setState(() {
        exportHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error al cargar historial: $e');
    }
  }

  Future<void> _requestDataExport() async {
    if (selectedDataTypes.isEmpty) {
      _showErrorSnackBar('Selecciona al menos un tipo de dato');
      return;
    }

    try {
      setState(() {
        isRequestingExport = true;
      });

      final result = await ExportService.requestDataExport(
        dataTypes: selectedDataTypes.toList(),
        format: selectedFormat,
      );

      _showSuccessSnackBar('Solicitud de exportación enviada');
      _loadExportHistory(); // Recargar historial
    } catch (e) {
      _showErrorSnackBar('Error al solicitar exportación: $e');
    } finally {
      setState(() {
        isRequestingExport = false;
      });
    }
  }

  Future<void> _downloadExport(String exportId) async {
    try {
      final data = await ExportService.downloadExport(exportId);
      // Aquí podrías implementar la lógica para guardar el archivo
      _showSuccessSnackBar('Archivo descargado correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al descargar archivo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'processing':
        return 'orange';
      case 'failed':
        return 'red';
      default:
        return 'grey';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completado';
      case 'processing':
        return 'Procesando';
      case 'failed':
        return 'Fallido';
      default:
        return 'Pendiente';
    }
  }

  String _getDataTypeText(String type) {
    switch (type) {
      case 'profile':
        return 'Perfil';
      case 'orders':
        return 'Pedidos';
      case 'activity':
        return 'Actividad';
      case 'reviews':
        return 'Reseñas';
      case 'addresses':
        return 'Direcciones';
      case 'notifications':
        return 'Notificaciones';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Datos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información sobre exportación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exportar tus datos personales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes solicitar una copia de todos los datos que tenemos sobre ti. '
                      'La exportación puede tardar hasta 24 horas en completarse.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selección de tipos de datos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipos de datos a exportar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableDataTypes.map((type) => CheckboxListTile(
                      title: Text(_getDataTypeText(type)),
                      value: selectedDataTypes.contains(type),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedDataTypes.add(type);
                          } else {
                            selectedDataTypes.remove(type);
                          }
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selección de formato
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formato de exportación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableFormats.map((format) => RadioListTile<String>(
                      title: Text(format.toUpperCase()),
                      value: format,
                      groupValue: selectedFormat,
                      onChanged: (String? value) {
                        setState(() {
                          selectedFormat = value!;
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón de solicitar exportación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isRequestingExport ? null : _requestDataExport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isRequestingExport
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Solicitar Exportación',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Historial de exportaciones
            const Text(
              'Historial de exportaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (exportHistory.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay exportaciones previas',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...exportHistory.map((export) => _buildExportHistoryCard(export)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportHistoryCard(Map<String, dynamic> export) {
    final id = export['id'] ?? '';
    final status = export['status'] ?? '';
    final format = export['format'] ?? '';
    final dataTypes = List<String>.from(export['data_types'] ?? []);
    final createdAt = DateTime.tryParse(export['created_at'] ?? '');
    final completedAt = export['completed_at'] != null
        ? DateTime.tryParse(export['completed_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Exportación ${format.toUpperCase()}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipos: ${dataTypes.map(_getDataTypeText).join(', ')}'),
            if (createdAt != null)
              Text('Solicitado: ${_formatDate(createdAt)}'),
            if (completedAt != null)
              Text('Completado: ${_formatDate(completedAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status) == 'green'
                    ? Colors.green
                    : _getStatusColor(status) == 'orange'
                        ? Colors.orange
                        : _getStatusColor(status) == 'red'
                            ? Colors.red
                            : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            if (status.toLowerCase() == 'completed') ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadExport(id),
              ),
            ],
          ],
        ),
        onTap: () => _showExportDetails(export),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showExportDetails(Map<String, dynamic> export) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de exportación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${export['id']}'),
            Text('Estado: ${_getStatusText(export['status'] ?? '')}'),
            Text('Formato: ${export['format']?.toUpperCase()}'),
            Text('Tipos de datos: ${(export['data_types'] as List<dynamic>?)?.map(_getDataTypeText).join(', ')}'),
            if (export['created_at'] != null)
              Text('Solicitado: ${_formatDate(DateTime.parse(export['created_at']))}'),
            if (export['completed_at'] != null)
              Text('Completado: ${_formatDate(DateTime.parse(export['completed_at']))}'),
            if (export['file_size'] != null)
              Text('Tamaño: ${export['file_size']} bytes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (export['status']?.toLowerCase() == 'completed')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadExport(export['id']);
              },
              child: const Text('Descargar'),
            ),
        ],
      ),
    );
  }
} 