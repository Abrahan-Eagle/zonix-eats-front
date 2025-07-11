import 'package:flutter/material.dart';

class TransportSettingsPage extends StatefulWidget {
  const TransportSettingsPage({super.key});

  @override
  State<TransportSettingsPage> createState() => _TransportSettingsPageState();
}

class _TransportSettingsPageState extends State<TransportSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoAssignOrders = true;
  bool _trackingEnabled = true;
  bool _maintenanceAlerts = true;
  String _selectedLanguage = 'Español';
  String _selectedCurrency = 'USD';
  double _serviceRadius = 15.0;
  double _maxDeliveryTime = 45.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Transporte'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Information
            _buildSectionCard(
              'Información de la Empresa',
              [
                _buildInfoTile('Nombre', 'TransportExpress S.A.'),
                _buildInfoTile('RUC', '20123456789'),
                _buildInfoTile('Dirección', 'Av. Principal 123, Ciudad'),
                _buildInfoTile('Teléfono', '+51 123 456 789'),
                _buildInfoTile('Email', 'info@transportexpress.com'),
                _buildInfoTile('Zona de Operación', 'Lima Metropolitana'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Operational Settings
            _buildSectionCard(
              'Configuración Operacional',
              [
                _buildSliderTile(
                  'Radio de Servicio',
                  '${_serviceRadius.toInt()} km',
                  _serviceRadius,
                  5.0,
                  50.0,
                  (value) => setState(() => _serviceRadius = value),
                ),
                _buildSliderTile(
                  'Tiempo Máximo de Entrega',
                  '${_maxDeliveryTime.toInt()} min',
                  _maxDeliveryTime,
                  15.0,
                  120.0,
                  (value) => setState(() => _maxDeliveryTime = value),
                ),
                _buildSwitchTile(
                  'Asignación Automática',
                  'Asignar pedidos automáticamente a conductores disponibles',
                  _autoAssignOrders,
                  (value) => setState(() => _autoAssignOrders = value),
                ),
                _buildSwitchTile(
                  'Seguimiento en Tiempo Real',
                  'Habilitar GPS tracking para conductores',
                  _trackingEnabled,
                  (value) => setState(() => _trackingEnabled = value),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Notification Settings
            _buildSectionCard(
              'Configuración de Notificaciones',
              [
                _buildSwitchTile(
                  'Notificaciones Push',
                  'Recibir alertas de nuevos pedidos y actualizaciones',
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildSwitchTile(
                  'Alertas de Mantenimiento',
                  'Notificaciones sobre mantenimiento de vehículos',
                  _maintenanceAlerts,
                  (value) => setState(() => _maintenanceAlerts = value),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Regional Settings
            _buildSectionCard(
              'Configuración Regional',
              [
                _buildDropdownTile(
                  'Idioma',
                  _selectedLanguage,
                  ['Español', 'English', 'Português'],
                  (value) => setState(() => _selectedLanguage = value!),
                ),
                _buildDropdownTile(
                  'Moneda',
                  _selectedCurrency,
                  ['USD', 'PEN', 'EUR'],
                  (value) => setState(() => _selectedCurrency = value!),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Fleet Management
            _buildSectionCard(
              'Gestión de Flota',
              [
                _buildActionTile(
                  'Gestionar Vehículos',
                  'Agregar, editar o eliminar vehículos de la flota',
                  Icons.directions_car,
                  () => _showFleetManagement(),
                ),
                _buildActionTile(
                  'Gestionar Conductores',
                  'Administrar conductores y permisos',
                  Icons.people,
                  () => _showDriverManagement(),
                ),
                _buildActionTile(
                  'Horarios de Trabajo',
                  'Configurar turnos y horarios de conductores',
                  Icons.schedule,
                  () => _showScheduleManagement(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Pricing & Commission
            _buildSectionCard(
              'Precios y Comisiones',
              [
                _buildActionTile(
                  'Configurar Tarifas',
                  'Establecer precios por distancia y tiempo',
                  Icons.attach_money,
                  () => _showPricingSettings(),
                ),
                _buildActionTile(
                  'Comisiones de Conductores',
                  'Configurar porcentajes de comisión',
                  Icons.percent,
                  () => _showCommissionSettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Security & Privacy
            _buildSectionCard(
              'Seguridad y Privacidad',
              [
                _buildActionTile(
                  'Cambiar Contraseña',
                  'Actualizar contraseña de acceso',
                  Icons.lock,
                  () => _showChangePassword(),
                ),
                _buildActionTile(
                  'Configuración de Privacidad',
                  'Gestionar datos personales y ubicación',
                  Icons.privacy_tip,
                  () => _showPrivacySettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // System Information
            _buildSectionCard(
              'Información del Sistema',
              [
                _buildInfoTile('Versión de la App', '2.1.0'),
                _buildInfoTile('Última Actualización', '15/12/2024'),
                _buildInfoTile('Soporte Técnico', 'soporte@transportexpress.com'),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showBackupDialog();
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Respaldar Configuración'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _saveSettings();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  _showLogoutDialog();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue[700],
    );
  }

  Widget _buildSliderTile(String title, String value, double sliderValue, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        Slider(
          value: sliderValue,
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          activeColor: Colors.blue[700],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: value,
            items: options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showFleetManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestión de Flota'),
        content: const Text('Aquí puedes gestionar los vehículos de tu flota.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDriverManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestión de Conductores'),
        content: const Text('Administra conductores y sus permisos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showScheduleManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horarios de Trabajo'),
        content: const Text('Configura turnos y horarios de conductores.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPricingSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Tarifas'),
        content: const Text('Establece precios por distancia y tiempo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCommissionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comisiones de Conductores'),
        content: const Text('Configura porcentajes de comisión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text('Función para cambiar contraseña.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Privacidad'),
        content: const Text('Gestiona datos personales y ubicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respaldar Configuración'),
        content: const Text('¿Deseas respaldar la configuración actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración respaldada exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Respaldar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada exitosamente')),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesión cerrada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 