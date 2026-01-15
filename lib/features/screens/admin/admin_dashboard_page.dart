import 'package:flutter/material.dart';
import 'package:zonix/features/services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
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
        title: Text('Panel de Administración'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error: $_error'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSystemHealthCard(),
                        SizedBox(height: 24),
                        _buildSystemStatsGrid(),
                        SizedBox(height: 24),
                        _buildUserDistributionChart(),
                        SizedBox(height: 24),
                        _buildQuickActions(),
                        SizedBox(height: 24),
                        _buildRecentActivity(),
                        SizedBox(height: 24),
                        _buildAnalyticsChart(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSystemHealthCard() {
    if (_systemHealth == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Estado del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
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
            SizedBox(height: 20),
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResourceUsage('CPU', _systemHealth!['cpu_usage']?.toString() ?? '0%', Colors.blue),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildResourceUsage('Memoria', _systemHealth!['memory_usage']?.toString() ?? '0%', Colors.green),
                ),
                SizedBox(width: 16),
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
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
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
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            SizedBox(width: 8),
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
    if (_systemStats == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas del Sistema',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
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
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
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
    if (_systemStats == null || _systemStats!['user_distribution'] == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución de Usuarios por Rol',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDistributionItem('Compradores', _systemStats!['user_distribution']['buyers'], Colors.blue),
                _buildDistributionItem('Comercios', _systemStats!['user_distribution']['commerce'], Colors.green),
                _buildDistributionItem('Delivery', _systemStats!['user_distribution']['delivery'], Colors.orange),
                _buildDistributionItem('Transporte', _systemStats!['user_distribution']['transport'], Colors.purple),
                _buildDistributionItem('Afiliados', _systemStats!['user_distribution']['affiliate'], Colors.red),
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
      padding: EdgeInsets.symmetric(vertical: 8),
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
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
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
        Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
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
            SizedBox(width: 12),
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
        SizedBox(height: 12),
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
            SizedBox(width: 12),
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
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
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
        Text(
          'Actividad Reciente del Sistema',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
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
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showActivityDetails(activity),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsChart() {
    if (_analytics == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crecimiento de Usuarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: _analytics!['user_growth'].map<Widget>((data) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          data['date'],
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${data['value']} usuarios',
                          textAlign: TextAlign.right,
                          style: TextStyle(
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
        title: Text('Detalles de Actividad'),
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
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _navigateToUserManagement() {
    // TODO: Navigate to user management page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Gestión de Usuarios')),
    );
  }

  void _navigateToSecurity() {
    // TODO: Navigate to security page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Seguridad')),
    );
  }

  void _navigateToAnalytics() {
    // TODO: Navigate to analytics page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Analytics')),
    );
  }

  void _navigateToSettings() {
    // TODO: Navigate to settings page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Configuración')),
    );
  }
} 