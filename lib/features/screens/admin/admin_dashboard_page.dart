import 'package:flutter/material.dart';
import 'package:zonix/features/screens/admin/admin_analytics_page.dart';
import 'package:zonix/features/screens/admin/admin_security_page.dart';
import 'package:zonix/features/screens/admin/admin_users_page.dart';
import 'package:zonix/features/screens/settings/settings_page_2.dart';
import 'package:zonix/features/services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _systemStats;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _systemHealth;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final systemStats = await _adminService.getSystemStatistics();
      final analytics = await _adminService.getAnalytics();
      final systemHealth = await _adminService.getSystemHealth();

      setState(() {
        _systemStats = systemStats;
        _analytics = analytics;
        _systemHealth = systemHealth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
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
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSystemHealthCard(),
                        const SizedBox(height: 24),
                        _buildSystemStatsGrid(),
                        const SizedBox(height: 24),
                        _buildUserDistributionChart(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildRecentActivity(),
                        const SizedBox(height: 24),
                        _buildAnalyticsChart(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSystemHealthCard() {
    if (_systemHealth == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Estado del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Saludable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric('Uptime', _systemHealth!['uptime']?.toString() ?? 'N/A', Icons.timer),
                ),
                Expanded(
                  child: _buildHealthMetric('Respuesta', _systemHealth!['response_time']?.toString() ?? 'N/A', Icons.speed),
                ),
                Expanded(
                  child: _buildHealthMetric('Conexiones', _systemHealth!['active_connections']?.toString() ?? '0', Icons.people),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResourceUsage('CPU', _systemHealth!['cpu_usage']?.toString() ?? '0%', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResourceUsage('Memoria', _systemHealth!['memory_usage']?.toString() ?? '0%', Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResourceUsage('Disco', _systemHealth!['disk_usage']?.toString() ?? '0%', Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceUsage(String label, String value, Color color) {
    final percentage = double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemStatsGrid() {
    if (_systemStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas del Sistema',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Usuarios',
              _systemStats!['total_users'].toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Usuarios Activos',
              _systemStats!['active_users'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Usuarios Suspendidos',
              _systemStats!['suspended_users'].toString(),
              Icons.block,
              Colors.red,
            ),
            _buildStatCard(
              'Verificados',
              _systemStats!['verification_status']['verified'].toString(),
              Icons.verified,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    if (_systemStats == null || _systemStats!['user_distribution'] == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución de Usuarios por Rol',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDistributionItem('Compradores', _systemStats!['user_distribution']['buyers'], Colors.blue),
                _buildDistributionItem('Comercios', _systemStats!['user_distribution']['commerce'], Colors.green),
                _buildDistributionItem('Delivery', _systemStats!['user_distribution']['delivery'], Colors.orange),
                _buildDistributionItem('Administradores', _systemStats!['user_distribution']['admin'], Colors.purple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionItem(String label, int count, Color color) {
    final total = _systemStats!['total_users'];
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Gestionar Usuarios',
                Icons.people,
                Colors.blue,
                () => _navigateToUserManagement(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Seguridad',
                Icons.security,
                Colors.red,
                () => _navigateToSecurity(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Analytics',
                Icons.analytics,
                Colors.green,
                () => _navigateToAnalytics(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Configuración',
                Icons.settings,
                Colors.grey,
                () => _navigateToSettings(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente del Sistema',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              final activities = [
                {'action': 'Nuevo usuario registrado', 'user': 'Juan Pérez', 'time': '2 min'},
                {'action': 'Usuario suspendido', 'user': 'Ana Martínez', 'time': '15 min'},
                {'action': 'Login exitoso', 'user': 'María González', 'time': '1 hora'},
                {'action': 'Cambio de contraseña', 'user': 'Carlos Rodríguez', 'time': '2 horas'},
                {'action': 'Login fallido', 'user': 'Luis Fernández', 'time': '3 horas'},
              ];

              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getActivityColor(activity['action']!),
                  child: Icon(
                    _getActivityIcon(activity['action']!),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(activity['action']!),
                subtitle: Text('${activity['user']} • Hace ${activity['time']}'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showActivityDetails(activity),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsChart() {
    if (_analytics == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crecimiento de Usuarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analytics!['user_growth'].map<Widget>((data) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          data['date'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${data['value']} usuarios',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String action) {
    if (action.contains('suspendido')) return Colors.red;
    if (action.contains('exitoso')) return Colors.green;
    if (action.contains('fallido')) return Colors.orange;
    if (action.contains('registrado')) return Colors.blue;
    return Colors.grey;
  }

  IconData _getActivityIcon(String action) {
    if (action.contains('suspendido')) return Icons.block;
    if (action.contains('exitoso')) return Icons.check_circle;
    if (action.contains('fallido')) return Icons.error;
    if (action.contains('registrado')) return Icons.person_add;
    if (action.contains('contraseña')) return Icons.lock;
    return Icons.info;
  }

  void _showActivityDetails(Map<String, String> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Actividad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acción: ${activity['action']}'),
            Text('Usuario: ${activity['user']}'),
            Text('Tiempo: Hace ${activity['time']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminUsersPage()),
    );
  }

  void _navigateToSecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSecurityPage()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAnalyticsPage()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage2()),
    );
  }
} 