import 'package:flutter/material.dart';
import '../services/privacy_service.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  Map<String, dynamic> privacySettings = {};
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      setState(() {
        isLoading = true;
      });

      final settings = await PrivacyService.getPrivacySettings();
      setState(() {
        privacySettings = settings;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error al cargar configuración: $e');
    }
  }

  Future<void> _updatePrivacySettings(Map<String, dynamic> updates) async {
    try {
      setState(() {
        isSaving = true;
      });

      final result = await PrivacyService.updatePrivacySettings(
        profileVisibility: updates['profile_visibility'],
        orderHistoryVisibility: updates['order_history_visibility'],
        activityVisibility: updates['activity_visibility'],
        marketingEmails: updates['marketing_emails'],
        pushNotifications: updates['push_notifications'],
        locationSharing: updates['location_sharing'],
        dataAnalytics: updates['data_analytics'],
      );

      setState(() {
        privacySettings = result;
        isSaving = false;
      });

      _showSuccessSnackBar('Configuración actualizada');
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      _showErrorSnackBar('Error al actualizar configuración: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Privacidad'),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            'Controla tu privacidad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gestiona cómo se utilizan y comparten tus datos personales.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Visibilidad del perfil
                  _buildPrivacySection(
                    title: 'Visibilidad del perfil',
                    description: 'Controla quién puede ver tu información personal',
                    children: [
                      SwitchListTile(
                        title: const Text('Perfil público'),
                        subtitle: const Text('Permitir que otros usuarios vean tu perfil'),
                        value: privacySettings['profile_visibility'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'profile_visibility': value,
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Historial de pedidos
                  _buildPrivacySection(
                    title: 'Historial de pedidos',
                    description: 'Controla la visibilidad de tu historial de compras',
                    children: [
                      SwitchListTile(
                        title: const Text('Historial visible'),
                        subtitle: const Text('Permitir que se vea tu historial de pedidos'),
                        value: privacySettings['order_history_visibility'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'order_history_visibility': value,
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Actividad
                  _buildPrivacySection(
                    title: 'Actividad',
                    description: 'Controla la visibilidad de tu actividad en la app',
                    children: [
                      SwitchListTile(
                        title: const Text('Actividad visible'),
                        subtitle: const Text('Permitir que se vea tu actividad reciente'),
                        value: privacySettings['activity_visibility'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'activity_visibility': value,
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notificaciones
                  _buildPrivacySection(
                    title: 'Notificaciones',
                    description: 'Controla cómo recibes notificaciones',
                    children: [
                      SwitchListTile(
                        title: const Text('Emails de marketing'),
                        subtitle: const Text('Recibir promociones y ofertas por email'),
                        value: privacySettings['marketing_emails'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'marketing_emails': value,
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Notificaciones push'),
                        subtitle: const Text('Recibir notificaciones en el dispositivo'),
                        value: privacySettings['push_notifications'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'push_notifications': value,
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ubicación
                  _buildPrivacySection(
                    title: 'Ubicación',
                    description: 'Controla el uso de tu ubicación',
                    children: [
                      SwitchListTile(
                        title: const Text('Compartir ubicación'),
                        subtitle: const Text('Permitir el acceso a tu ubicación'),
                        value: privacySettings['location_sharing'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'location_sharing': value,
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Análisis de datos
                  _buildPrivacySection(
                    title: 'Análisis de datos',
                    description: 'Controla el uso de datos para análisis',
                    children: [
                      SwitchListTile(
                        title: const Text('Análisis de datos'),
                        subtitle: const Text('Permitir el uso de datos para mejorar el servicio'),
                        value: privacySettings['data_analytics'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'data_analytics': value,
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Enlaces a políticas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Políticas y términos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Política de privacidad'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _showPrivacyPolicy,
                          ),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Términos de servicio'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _showTermsOfService,
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

  Widget _buildPrivacySection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    try {
      final policy = await PrivacyService.getPrivacyPolicy();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Política de Privacidad'),
            content: SingleChildScrollView(
              child: Text(policy['content'] ?? 'Política no disponible'),
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
    } catch (e) {
      _showErrorSnackBar('Error al cargar política: $e');
    }
  }

  Future<void> _showTermsOfService() async {
    try {
      final terms = await PrivacyService.getTermsOfService();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Términos de Servicio'),
            content: SingleChildScrollView(
              child: Text(terms['content'] ?? 'Términos no disponibles'),
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
    } catch (e) {
      _showErrorSnackBar('Error al cargar términos: $e');
    }
  }
} 