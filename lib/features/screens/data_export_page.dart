import 'package:flutter/material.dart';
import '../services/export_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

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

      await ExportService.requestDataExport(
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
      await ExportService.downloadExport(exportId);
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
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
                AppColors.headerGradientEnd(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Exportar Datos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: const IconThemeData(color: AppColors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.cardBg(context),
              shadowColor: AppColors.orange.withValues(alpha: 0.10),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exportar tus datos personales', // TODO: internacionalizar
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Puedes solicitar una copia de todos los datos que tenemos sobre ti. La exportación puede tardar hasta 24 horas en completarse.', // TODO: internacionalizar
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.cardBg(context),
              shadowColor: AppColors.orange.withValues(alpha: 0.10),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipos de datos a exportar', // TODO: internacionalizar
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
                      activeColor: AppColors.accentButton(context),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.cardBg(context),
              shadowColor: AppColors.orange.withValues(alpha: 0.10),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formato de exportación', // TODO: internacionalizar
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...availableFormats.map((format) => RadioListTile<String>(
                      title: Text(format.toUpperCase()),
                      value: format,
                      groupValue: selectedFormat, // ignore: deprecated_member_use
                      onChanged: (value) { // ignore: deprecated_member_use
                        setState(() {
                          selectedFormat = value!;
                        });
                      },
                      activeColor: AppColors.accentButton(context),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: isRequestingExport ? null : _requestDataExport,
                icon: const Icon(Icons.download, color: Colors.white),
                label: isRequestingExport
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Solicitar exportación', style: TextStyle(color: Colors.white, fontSize: 18)), // TODO: internacionalizar
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.cardBg(context),
              shadowColor: AppColors.orange.withValues(alpha: 0.10),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historial de exportaciones', // TODO: internacionalizar
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (exportHistory.isEmpty)
                      const Text('No hay exportaciones previas', style: TextStyle(color: Colors.grey)) // TODO: internacionalizar
                    else
                      ...exportHistory.map((item) => ListTile(
                        leading: Icon(Icons.file_download, color: AppColors.accentButton(context)),
                        title: Text(_getStatusText(item['status'])),
                        subtitle: Text(item['created_at'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          onPressed: () => _downloadExport(item['id']),
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

} 