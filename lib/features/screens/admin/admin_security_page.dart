import 'package:flutter/material.dart';
import 'package:zonix/features/services/admin_service.dart';

class AdminSecurityPage extends StatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  State<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends State<AdminSecurityPage> {
  bool _twoFactorEnabled = true;
  bool _loginNotifications = true;
  bool _suspiciousActivityAlerts = true;
  bool _autoLockEnabled = true;
  int _sessionTimeout = 30;

  List<Map<String, dynamic>> _securityEvents = [];
  bool _loading = true;
  String? _errorMessage;

  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _loadSecurityEvents();
  }

  Future<void> _loadSecurityEvents() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final events = await _adminService.getSecurityLogs();
      setState(() {
        _securityEvents = events.map(_normalizeEvent).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeEvent(Map<String, dynamic> raw) {
    return {
      'type': raw['type'] ?? raw['action'] ?? raw['event_type'] ?? 'Evento',
      'user': raw['user'] ?? raw['user_email'] ?? raw['email'] ?? 'Desconocido',
      'ip': raw['ip'] ?? raw['ip_address'] ?? 'N/A',
      'time': raw['time'] ?? raw['created_at'] ?? raw['timestamp'] ?? 'N/A',
      'status': raw['status'] ?? raw['result'] ?? 'Info',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguridad del Sistema'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              _showSecurityScan();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Overview
            const Text('Resumen de Seguridad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildSecurityOverviewCard(),
            
            const SizedBox(height: 24),
            
            // Security Settings
            const Text('Configuración de Seguridad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildSecuritySettingsCard(),
            
            const SizedBox(height: 24),
            
            // Recent Security Events
            const Text('Eventos de Seguridad Recientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildSecurityEventsCard(),
            
            const SizedBox(height: 24),
            
            // Access Control
            const Text('Control de Acceso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAccessControlCard(),
            
            const SizedBox(height: 24),
            
            // Threat Monitoring
            const Text('Monitoreo de Amenazas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildThreatMonitoringCard(),
            
            const SizedBox(height: 24),
            
            // Backup & Recovery
            const Text('Respaldo y Recuperación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildBackupRecoveryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOverviewCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSecurityMetric('Nivel de Seguridad', 'Alto', Colors.green, Icons.shield),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecurityMetric('Intentos de Acceso', '3', Colors.orange, Icons.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecurityMetric('Sesiones Activas', '45', Colors.blue, Icons.people),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistema seguro. Último escaneo: Hace 2 horas',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetric(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Autenticación de Dos Factores'),
              subtitle: const Text('Requerir 2FA para todos los usuarios'),
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() {
                  _twoFactorEnabled = value;
                });
              },
              activeThumbColor: Colors.red[700],
            ),
            SwitchListTile(
              title: const Text('Notificaciones de Login'),
              subtitle: const Text('Alertar sobre inicios de sesión'),
              value: _loginNotifications,
              onChanged: (value) {
                setState(() {
                  _loginNotifications = value;
                });
              },
              activeThumbColor: Colors.red[700],
            ),
            SwitchListTile(
              title: const Text('Alertas de Actividad Sospechosa'),
              subtitle: const Text('Detectar comportamientos anómalos'),
              value: _suspiciousActivityAlerts,
              onChanged: (value) {
                setState(() {
                  _suspiciousActivityAlerts = value;
                });
              },
              activeThumbColor: Colors.red[700],
            ),
            SwitchListTile(
              title: const Text('Bloqueo Automático'),
              subtitle: const Text('Bloquear sesiones inactivas'),
              value: _autoLockEnabled,
              onChanged: (value) {
                setState(() {
                  _autoLockEnabled = value;
                });
              },
              activeThumbColor: Colors.red[700],
            ),
            ListTile(
              title: const Text('Tiempo de Sesión'),
              subtitle: Text('$_sessionTimeout minutos'),
              trailing: DropdownButton<int>(
                value: _sessionTimeout,
                items: [15, 30, 60, 120].map((time) {
                  return DropdownMenuItem(value: time, child: Text('$time min'));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _sessionTimeout = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPasswordPolicy();
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text('Política de Contraseñas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _saveSecuritySettings();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityEventsCard() {
    if (_loading) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Cargando eventos de seguridad...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
              const SizedBox(height: 16),
              Text(
                'Error al cargar eventos',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadSecurityEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_securityEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.security, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay eventos de seguridad recientes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _securityEvents.length,
                itemBuilder: (context, index) {
                  final event = _securityEvents[index];
                  final type = event['type']?.toString() ?? 'Evento';
                  final user = event['user']?.toString() ?? 'Desconocido';
                  final ip = event['ip']?.toString() ?? 'N/A';
                  final time = event['time']?.toString() ?? 'N/A';
                  final status = event['status']?.toString() ?? 'Info';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEventColor(status),
                      child: Icon(_getEventIcon(type), color: Colors.white, size: 16),
                    ),
                    title: Text('$type - $user'),
                    subtitle: Text('IP: $ip • $time'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEventColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getEventColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      _showEventDetails(event);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String status) {
    switch (status) {
      case 'Exitoso':
        return Colors.green;
      case 'Fallido':
        return Colors.red;
      case 'Advertencia':
        return Colors.orange;
      case 'Info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'Login':
        return Icons.login;
      case 'Acceso Denegado':
        return Icons.block;
      case 'Cambio de Contraseña':
        return Icons.lock;
      case 'Sesión Expirada':
        return Icons.timer_off;
      case 'Acceso Sospechoso':
        return Icons.warning;
      case 'Backup Completado':
        return Icons.backup;
      default:
        return Icons.security;
    }
  }

  Widget _buildAccessControlCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Control de Acceso', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAccessItem('Administradores', '5 usuarios', 'Acceso completo'),
            _buildAccessItem('Moderadores', '12 usuarios', 'Acceso limitado'),
            _buildAccessItem('Usuarios Regulares', '1,234 usuarios', 'Acceso básico'),
            _buildAccessItem('Usuarios Suspendidos', '8 usuarios', 'Sin acceso'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRoleManagement();
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Gestionar Roles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showPermissions();
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Permisos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessItem(String role, String count, String access) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(role, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(count, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(access, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatMonitoringCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monitoreo de Amenazas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildThreatItem('Ataques de Fuerza Bruta', '0 detectados', 'Bajo', Colors.green),
            _buildThreatItem('Accesos No Autorizados', '2 intentos', 'Medio', Colors.orange),
            _buildThreatItem('Actividad Sospechosa', '1 alerta', 'Bajo', Colors.green),
            _buildThreatItem('Malware Detectado', '0 archivos', 'Bajo', Colors.green),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistema de detección de amenazas activo. Última actualización: Hace 5 min',
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatItem(String threat, String status, String level, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(threat, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRecoveryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Respaldo y Recuperación', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildBackupItem('Último Respaldo', 'Hace 2 horas', 'Completado'),
            _buildBackupItem('Próximo Respaldo', 'En 22 horas', 'Programado'),
            _buildBackupItem('Tamaño del Respaldo', '2.5 GB', 'Comprimido'),
            _buildBackupItem('Retención', '30 días', 'Configurado'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _initiateBackup();
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Iniciar Respaldo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showRecoveryOptions();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Recuperación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(String label, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(value),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSecurityScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escaneo de Seguridad'),
        content: const Text('Iniciando escaneo completo del sistema...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Escaneo iniciado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Iniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPasswordPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Contraseñas'),
        content: const Text('Configurar requisitos de contraseñas'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _saveSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración de seguridad guardada')),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? 'Evento';
    final user = event['user']?.toString() ?? 'Desconocido';
    final ip = event['ip']?.toString() ?? 'N/A';
    final time = event['time']?.toString() ?? 'N/A';
    final status = event['status']?.toString() ?? 'Info';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Evento: $type'),
        content: Text('Usuario: $user\nIP: $ip\nHora: $time\nEstado: $status'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showRoleManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestión de Roles'),
        content: const Text('Configurar roles y permisos'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos'),
        content: const Text('Gestionar permisos de usuarios'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _initiateBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Respaldo'),
        content: const Text('¿Deseas iniciar un respaldo manual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Respaldo iniciado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Iniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRecoveryOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opciones de Recuperación'),
        content: const Text('Seleccionar punto de restauración'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
} 