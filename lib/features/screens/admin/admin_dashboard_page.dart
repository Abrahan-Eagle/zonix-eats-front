import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _selectedPeriod = 'Hoy';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos actualizados')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('Período: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _periods.map((period) {
                        return DropdownMenuItem(value: period, child: Text(period));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // System Overview
            const Text('Resumen del Sistema', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard('Usuarios Activos', '12,450', '+8%', Colors.blue, Icons.people),
                _buildMetricCard('Órdenes Totales', '8,920', '+15%', Colors.green, Icons.shopping_cart),
                _buildMetricCard('Ingresos', '\$45,230', '+12%', Colors.orange, Icons.attach_money),
                _buildMetricCard('Comercios', '156', '+5%', Colors.purple, Icons.store),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // System Status
            const Text('Estado del Sistema', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildSystemStatusCard(),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            const Text('Actividad Reciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildRecentActivityCard(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text('Acciones Rápidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildQuickActionsCard(),
            
            const SizedBox(height: 24),
            
            // Performance Metrics
            const Text('Métricas de Rendimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildPerformanceMetricsCard(),
            
            const SizedBox(height: 24),
            
            // Alerts & Issues
            const Text('Alertas y Problemas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAlertsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, Color color, IconData icon) {
    final isPositive = change.startsWith('+');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusItem('Servidor Principal', 'Operativo', Icons.check_circle, Colors.green),
            _buildStatusItem('Base de Datos', 'Operativo', Icons.check_circle, Colors.green),
            _buildStatusItem('API Gateway', 'Operativo', Icons.check_circle, Colors.green),
            _buildStatusItem('Sistema de Pagos', 'Operativo', Icons.check_circle, Colors.green),
            _buildStatusItem('Notificaciones', 'Advertencia', Icons.warning, Colors.orange),
            _buildStatusItem('Backup Automático', 'Operativo', Icons.check_circle, Colors.green),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistema funcionando correctamente. Tiempo de actividad: 99.8%',
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

  Widget _buildStatusItem(String service, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(service),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) {
                final activities = [
                  {'type': 'Usuario', 'action': 'Nuevo registro', 'details': 'Juan Pérez se registró', 'time': '2 min'},
                  {'type': 'Orden', 'action': 'Orden completada', 'details': 'Pedido #1234 entregado', 'time': '5 min'},
                  {'type': 'Comercio', 'action': 'Comercio aprobado', 'details': 'Pizza Express activado', 'time': '15 min'},
                  {'type': 'Sistema', 'action': 'Backup completado', 'details': 'Respaldo automático exitoso', 'time': '1 hora'},
                  {'type': 'Pago', 'action': 'Transacción procesada', 'details': 'Pago de \$45.00 procesado', 'time': '2 horas'},
                  {'type': 'Soporte', 'action': 'Ticket resuelto', 'details': 'Ticket #5678 cerrado', 'time': '3 horas'},
                ];
                
                final activity = activities[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActivityColor(activity['type']!),
                    child: Icon(_getActivityIcon(activity['type']!), color: Colors.white, size: 16),
                  ),
                  title: Text(activity['action']!),
                  subtitle: Text('${activity['details']} • Hace ${activity['time']}'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showActivityDetails(activity);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'Usuario':
        return Colors.blue;
      case 'Orden':
        return Colors.green;
      case 'Comercio':
        return Colors.purple;
      case 'Sistema':
        return Colors.orange;
      case 'Pago':
        return Colors.green;
      case 'Soporte':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Usuario':
        return Icons.person_add;
      case 'Orden':
        return Icons.shopping_cart;
      case 'Comercio':
        return Icons.store;
      case 'Sistema':
        return Icons.settings;
      case 'Pago':
        return Icons.payment;
      case 'Soporte':
        return Icons.support_agent;
      default:
        return Icons.info;
    }
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Gestionar Usuarios',
                    Icons.people,
                    Colors.blue,
                    () => _showUserManagement(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Ver Reportes',
                    Icons.assessment,
                    Colors.green,
                    () => _showReports(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Configuración',
                    Icons.settings,
                    Colors.orange,
                    () => _showSystemSettings(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Soporte',
                    Icons.support_agent,
                    Colors.purple,
                    () => _showSupport(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Métricas de Rendimiento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildMetricRow('Tiempo de Respuesta API', '120ms', 'Excelente'),
            _buildMetricRow('Uso de CPU', '45%', 'Normal'),
            _buildMetricRow('Uso de Memoria', '68%', 'Normal'),
            _buildMetricRow('Espacio en Disco', '78%', 'Advertencia'),
            _buildMetricRow('Conexiones Activas', '1,234', 'Normal'),
            _buildMetricRow('Errores por Hora', '2', 'Bajo'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El espacio en disco está al 78%. Considera limpiar archivos temporales.',
                      style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
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

  Widget _buildMetricRow(String metric, String value, String status) {
    Color statusColor;
    switch (status) {
      case 'Excelente':
        statusColor = Colors.green;
        break;
      case 'Normal':
        statusColor = Colors.blue;
        break;
      case 'Advertencia':
        statusColor = Colors.orange;
        break;
      case 'Bajo':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alertas y Problemas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAlertItem(
              'Espacio en disco bajo',
              'El servidor principal tiene 78% de uso',
              'Media',
              Colors.orange,
            ),
            _buildAlertItem(
              'Tiempo de respuesta lento',
              'La API está respondiendo en 120ms',
              'Baja',
              Colors.yellow,
            ),
            _buildAlertItem(
              'Backup programado',
              'Respaldo automático en 2 horas',
              'Info',
              Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showAllAlerts();
                    },
                    child: const Text('Ver Todas'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _acknowledgeAlerts();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                    child: const Text('Reconocer', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String description, String priority, Color color) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              priority,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones del Sistema'),
        content: const Text('No hay notificaciones nuevas'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(Map<String, String> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity['action']!),
        content: Text('${activity['details']}\n\nHora: ${activity['time']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showUserManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestión de Usuarios'),
        content: const Text('Accediendo al panel de gestión de usuarios...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportes del Sistema'),
        content: const Text('Generando reportes...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSystemSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración del Sistema'),
        content: const Text('Accediendo a la configuración...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soporte Técnico'),
        content: const Text('Conectando con soporte técnico...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAllAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Todas las Alertas'),
        content: const Text('Mostrando todas las alertas del sistema...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _acknowledgeAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertas reconocidas')),
    );
  }
} 