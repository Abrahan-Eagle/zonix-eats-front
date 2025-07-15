import 'package:flutter/material.dart';
import '../services/privacy_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

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
            title: const Text('Configuración de Privacidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: IconThemeData(color: AppColors.white),
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
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppColors.cardBg(context),
                    shadowColor: AppColors.purple.withOpacity(0.10),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Controla tu privacidad', // TODO: internacionalizar
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gestiona cómo se utilizan y comparten tus datos personales.', // TODO: internacionalizar
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'Visibilidad del perfil', // TODO: internacionalizar
                    description: 'Controla quién puede ver tu información personal', // TODO: internacionalizar
                    children: [
                      SwitchListTile(
                        title: const Text('Perfil público'), // TODO: internacionalizar
                        subtitle: const Text('Permitir que otros usuarios vean tu perfil'), // TODO: internacionalizar
                        value: privacySettings['profile_visibility'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'profile_visibility': value,
                          });
                        },
                        activeColor: AppColors.accentButton(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'Historial de pedidos', // TODO: internacionalizar
                    description: 'Controla la visibilidad de tu historial de compras', // TODO: internacionalizar
                    children: [
                      SwitchListTile(
                        title: const Text('Historial visible'), // TODO: internacionalizar
                        subtitle: const Text('Permitir que se vea tu historial de pedidos'), // TODO: internacionalizar
                        value: privacySettings['order_history_visibility'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'order_history_visibility': value,
                          });
                        },
                        activeColor: AppColors.accentButton(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'Actividad', // TODO: internacionalizar
                    description: 'Controla la visibilidad de tu actividad en la app', // TODO: internacionalizar
                    children: [
                      SwitchListTile(
                        title: const Text('Actividad visible'), // TODO: internacionalizar
                        subtitle: const Text('Permitir que se vea tu actividad reciente'), // TODO: internacionalizar
                        value: privacySettings['activity_visibility'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'activity_visibility': value,
                          });
                        },
                        activeColor: AppColors.accentButton(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'Notificaciones', // TODO: internacionalizar
                    description: 'Controla cómo recibes notificaciones', // TODO: internacionalizar
                    children: [
                      SwitchListTile(
                        title: const Text('Emails de marketing'), // TODO: internacionalizar
                        subtitle: const Text('Recibir promociones y ofertas por email'), // TODO: internacionalizar
                        value: privacySettings['marketing_emails'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'marketing_emails': value,
                          });
                        },
                        activeColor: AppColors.accentButton(context),
                      ),
                      SwitchListTile(
                        title: const Text('Notificaciones push'), // TODO: internacionalizar
                        subtitle: const Text('Recibir notificaciones en el dispositivo'), // TODO: internacionalizar
                        value: privacySettings['push_notifications'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'push_notifications': value,
                          });
                        },
                        activeColor: AppColors.accentButton(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    title: 'Ubicación', // TODO: internacionalizar
                    description: 'Controla el uso de tu ubicación', // TODO: internacionalizar
                    children: [
                      SwitchListTile(
                        title: const Text('Compartir ubicación'), // TODO: internacionalizar
                        subtitle: const Text('Permitir el acceso a tu ubicación'), // TODO: internacionalizar
                        value: privacySettings['location_sharing'] ?? false,
                        onChanged: (bool value) {
                          _updatePrivacySettings({
                            'location_sharing': value,
                          });
                        },
                        activeColor: AppColors.accentButton(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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