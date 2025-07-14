import 'package:flutter/material.dart';
import 'activity_history_page.dart';
import 'data_export_page.dart';
import 'privacy_settings_page.dart';
import 'account_deletion_page.dart';

class AdvancedUserFeaturesPage extends StatelessWidget {
  const AdvancedUserFeaturesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionalidades Avanzadas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Funcionalidades de Usuario Avanzado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accede a herramientas avanzadas para gestionar tu cuenta, '
                      'datos personales y privacidad.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Historial de actividad
            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'Historial de Actividad',
              description: 'Revisa todas tus actividades en la aplicación',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityHistoryPage(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Exportación de datos
            _buildFeatureCard(
              context,
              icon: Icons.download,
              title: 'Exportar Datos',
              description: 'Descarga una copia de todos tus datos personales',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataExportPage(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Configuración de privacidad
            _buildFeatureCard(
              context,
              icon: Icons.privacy_tip,
              title: 'Configuración de Privacidad',
              description: 'Controla cómo se utilizan y comparten tus datos',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsPage(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Eliminación de cuenta
            _buildFeatureCard(
              context,
              icon: Icons.delete_forever,
              title: 'Eliminar Cuenta',
              description: 'Elimina permanentemente tu cuenta y todos tus datos',
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountDeletionPage(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Información adicional
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Información importante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estas funcionalidades están diseñadas para darte control total '
                      'sobre tu cuenta y datos personales. Todas las acciones son '
                      'reversibles excepto la eliminación de cuenta.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 