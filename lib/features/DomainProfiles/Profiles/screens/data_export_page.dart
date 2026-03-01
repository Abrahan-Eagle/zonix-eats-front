import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final logger = Logger();

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _exportData;
  bool _isLoading = false;
  String? _error;
  String _selectedFormat = 'json';

  Future<void> _requestDataExport() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _profileService.exportPersonalData();
      setState(() {
        _exportData = data;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos exportados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      logger.e('Error exporting data: $e');
    }
  }

  void _showDataPreview() {
    if (_exportData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vista Previa de Datos'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              _selectedFormat == 'json' 
                  ? const JsonEncoder.withIndent('  ').convert(_exportData)
                  : _formatDataAsText(_exportData!),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatDataAsText(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== DATOS PERSONALES EXPORTADOS ===\n');
    
    // Información del perfil
    if (data['profile'] != null) {
      buffer.writeln('PERFIL:');
      final profile = data['profile'];
      buffer.writeln('  Nombre: ${profile['firstName']} ${profile['lastName']}');
      buffer.writeln('  Email: ${profile['email'] ?? 'N/A'}');
      buffer.writeln('  Fecha de nacimiento: ${profile['date_of_birth'] ?? 'N/A'}');
      buffer.writeln('  Estado civil: ${profile['maritalStatus'] ?? 'N/A'}');
      buffer.writeln('  Sexo: ${profile['sex'] ?? 'N/A'}');
      buffer.writeln('');
    }
    
    // Direcciones
    if (data['addresses'] != null && data['addresses'].isNotEmpty) {
      buffer.writeln('DIRECCIONES:');
      for (int i = 0; i < data['addresses'].length; i++) {
        final address = data['addresses'][i];
        buffer.writeln('  ${i + 1}. ${address['street']}, ${address['city']}');
      }
      buffer.writeln('');
    }
    
    // Órdenes
    if (data['orders'] != null && data['orders'].isNotEmpty) {
      buffer.writeln('ÓRDENES (${data['orders'].length}):');
      for (int i = 0; i < data['orders'].length; i++) {
        final order = data['orders'][i];
        buffer.writeln('  ${i + 1}. Orden #${order['id']} - ${order['status']} - \$${order['total']}');
      }
      buffer.writeln('');
    }
    
    // Reseñas
    if (data['reviews'] != null && data['reviews'].isNotEmpty) {
      buffer.writeln('RESEÑAS (${data['reviews'].length}):');
      for (int i = 0; i < data['reviews'].length; i++) {
        final review = data['reviews'][i];
        buffer.writeln('  ${i + 1}. ${review['rating']} estrellas - ${review['comment']}');
      }
      buffer.writeln('');
    }
    
    // Actividad
    if (data['activity'] != null && data['activity'].isNotEmpty) {
      buffer.writeln('ACTIVIDAD RECIENTE (${data['activity'].length}):');
      for (int i = 0; i < data['activity'].length; i++) {
        final activity = data['activity'][i];
        buffer.writeln('  ${i + 1}. ${activity['type']} - ${activity['description']}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('Fecha de exportación: ${DateTime.now()}');
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Datos Personales'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Información sobre la exportación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Qué incluye la exportación?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('Perfil personal', Icons.person),
                    _buildInfoItem('Direcciones guardadas', Icons.location_on),
                    _buildInfoItem('Historial de órdenes', Icons.shopping_cart),
                    _buildInfoItem('Reseñas y calificaciones', Icons.star),
                    _buildInfoItem('Actividad reciente', Icons.history),
                    _buildInfoItem('Preferencias', Icons.settings),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selector de formato
            const Text(
              'Formato de exportación:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('JSON'),
                    subtitle: const Text('Formato estructurado'),
                    value: 'json',
                    groupValue: _selectedFormat, // ignore: deprecated_member_use
                    onChanged: (value) { // ignore: deprecated_member_use
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Texto'),
                    subtitle: const Text('Formato legible'),
                    value: 'text',
                    groupValue: _selectedFormat, // ignore: deprecated_member_use
                    onChanged: (value) { // ignore: deprecated_member_use
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Botón de exportación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestDataExport,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isLoading ? 'Exportando...' : 'Exportar Datos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (_exportData != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos Exportados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDataSummary('Perfil', _exportData!['profile'] != null),
                      _buildDataSummary('Direcciones', _exportData!['addresses']?.isNotEmpty ?? false),
                      _buildDataSummary('Órdenes', _exportData!['orders']?.isNotEmpty ?? false),
                      _buildDataSummary('Reseñas', _exportData!['reviews']?.isNotEmpty ?? false),
                      _buildDataSummary('Actividad', _exportData!['activity']?.isNotEmpty ?? false),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showDataPreview,
                              icon: const Icon(Icons.visibility),
                              label: const Text('Vista Previa'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Aquí se implementaría la descarga real
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Descarga iniciada'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.file_download),
                              label: const Text('Descargar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildDataSummary(String title, bool hasData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            hasData ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: hasData ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: hasData ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 