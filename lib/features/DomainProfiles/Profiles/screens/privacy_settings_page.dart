import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _privacySettings;
  bool _isLoading = true;
  String? _error;

  // Controllers para los switches
  bool _profileVisible = true;
  bool _reviewsVisible = true;
  bool _orderHistoryVisible = true;
  bool _activityVisible = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _profileService.getPrivacySettings();
      setState(() {
        _privacySettings = data;
        _profileVisible = data['privacy_settings']['profile_visible'] ?? true;
        _reviewsVisible = data['privacy_settings']['reviews_visible'] ?? true;
        _orderHistoryVisible = data['privacy_settings']['order_history_visible'] ?? true;
        _activityVisible = data['privacy_settings']['activity_visible'] ?? true;
        _emailNotifications = data['privacy_settings']['email_notifications'] ?? true;
        _pushNotifications = data['privacy_settings']['push_notifications'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      logger.e('Error loading privacy settings: $e');
    }
  }

  Future<void> _updatePrivacySettings() async {
    try {
      final settings = {
        'profile_visible': _profileVisible,
        'reviews_visible': _reviewsVisible,
        'order_history_visible': _orderHistoryVisible,
        'activity_visible': _activityVisible,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
      };

      await _profileService.updatePrivacySettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración de privacidad actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      logger.e('Error updating privacy settings: $e');
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y se perderán todos tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteAccountConfirmation();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación Final'),
        content: const Text(
          'Esta es tu última oportunidad. Al eliminar tu cuenta:\n\n'
          '• Se eliminarán todos tus datos personales\n'
          '• Se cancelarán todas tus órdenes pendientes\n'
          '• Se perderá acceso a tu historial\n'
          '• No podrás recuperar tu cuenta\n\n'
          '¿Estás completamente seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SÍ, ELIMINAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await _profileService.deleteAccount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar al login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cuenta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      logger.e('Error deleting account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Privacidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updatePrivacySettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar la configuración',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPrivacySettings,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Sección de Visibilidad
                    const Text(
                      'Visibilidad del Perfil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Perfil Público'),
                      subtitle: const Text('Permitir que otros vean tu perfil'),
                      value: _profileVisible,
                      onChanged: (value) {
                        setState(() {
                          _profileVisible = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Reseñas Visibles'),
                      subtitle: const Text('Mostrar tus reseñas públicamente'),
                      value: _reviewsVisible,
                      onChanged: (value) {
                        setState(() {
                          _reviewsVisible = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Historial de Órdenes'),
                      subtitle: const Text('Permitir acceso al historial de compras'),
                      value: _orderHistoryVisible,
                      onChanged: (value) {
                        setState(() {
                          _orderHistoryVisible = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Actividad Visible'),
                      subtitle: const Text('Mostrar tu actividad reciente'),
                      value: _activityVisible,
                      onChanged: (value) {
                        setState(() {
                          _activityVisible = value;
                        });
                      },
                    ),
                    
                    const Divider(height: 32),
                    
                    // Sección de Notificaciones
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Notificaciones por Email'),
                      subtitle: const Text('Recibir actualizaciones por correo'),
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      title: const Text('Notificaciones Push'),
                      subtitle: const Text('Recibir notificaciones en la app'),
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                    ),
                    
                    const Divider(height: 32),
                    
                    // Sección de Eliminación de Cuenta
                    const Text(
                      'Eliminar Cuenta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      color: Colors.red[50],
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red[700]),
                        title: const Text(
                          'Eliminar Mi Cuenta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: const Text(
                          'Esta acción no se puede deshacer',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showDeleteAccountDialog,
                      ),
                    ),
                  ],
                ),
    );
  }
} 