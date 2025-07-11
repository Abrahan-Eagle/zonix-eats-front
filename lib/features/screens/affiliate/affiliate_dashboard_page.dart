import 'package:flutter/material.dart';
import 'package:zonix/features/services/affiliate_service.dart';

class AffiliateDashboardPage extends StatefulWidget {
  @override
  _AffiliateDashboardPageState createState() => _AffiliateDashboardPageState();
}

class _AffiliateDashboardPageState extends State<AffiliateDashboardPage> {
  final AffiliateService _affiliateService = AffiliateService();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _statistics;
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

      // Load profile and statistics for affiliate ID 1 (mock data)
      final profile = await _affiliateService.getAffiliateProfile(1);
      final statistics = await _affiliateService.getAffiliateStatistics(1);

      setState(() {
        _profile = profile;
        _statistics = statistics;
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
        title: Text('Dashboard de Afiliado'),
        backgroundColor: Colors.purple,
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
                        _buildProfileCard(),
                        SizedBox(height: 24),
                        _buildStatisticsGrid(),
                        SizedBox(height: 24),
                        _buildQuickActions(),
                        SizedBox(height: 24),
                        _buildRecentActivity(),
                        SizedBox(height: 24),
                        _buildPerformanceChart(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    if (_profile == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.purple[100],
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile!['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _profile!['email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getLevelColor(_profile!['level']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _profile!['level'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildProfileStat('Código', _profile!['referral_code']),
                ),
                Expanded(
                  child: _buildProfileStat('Estado', _getStatusText(_profile!['status'])),
                ),
                Expanded(
                  child: _buildProfileStat('Miembro desde', _profile!['join_date']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
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
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    if (_statistics == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas Generales',
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
              'Total Referidos',
              _statistics!['total_referrals'].toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Referidos Activos',
              _statistics!['active_referrals'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Comisión Total',
              '\$${_statistics!['total_commission'].toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.orange,
            ),
            _buildStatCard(
              'Comisión Pendiente',
              '\$${_statistics!['pending_commission'].toStringAsFixed(2)}',
              Icons.pending,
              Colors.red,
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
                'Ver Referidos',
                Icons.people,
                Colors.blue,
                () => _navigateToReferrals(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Comisiones',
                Icons.attach_money,
                Colors.orange,
                () => _navigateToCommissions(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Soporte',
                Icons.support_agent,
                Colors.green,
                () => _navigateToSupport(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Materiales',
                Icons.campaign,
                Colors.purple,
                () => _navigateToMarketingMaterials(),
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
    if (_statistics == null || _statistics!['recent_activity'] == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
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
            itemCount: _statistics!['recent_activity'].length,
            itemBuilder: (context, index) {
              final activity = _statistics!['recent_activity'][index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: activity['status'] == 'active' ? Colors.green[100] : Colors.grey[100],
                  child: Icon(
                    Icons.person,
                    color: activity['status'] == 'active' ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(activity['referral_name']),
                subtitle: Text('Último pedido: ${activity['last_order_date']}'),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: activity['status'] == 'active' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity['status'] == 'active' ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    if (_statistics == null || _statistics!['monthly_performance'] == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rendimiento Mensual',
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
              children: _statistics!['monthly_performance'].map<Widget>((month) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          month['month'],
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${month['referrals']} ref.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '\$${month['commission'].toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
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

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Bronze':
        return Colors.brown;
      case 'Silver':
        return Colors.grey;
      case 'Gold':
        return Colors.amber;
      case 'Platinum':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'pending':
        return 'Pendiente';
      case 'suspended':
        return 'Suspendido';
      default:
        return 'Desconocido';
    }
  }

  void _showEditProfileDialog() {
    // TODO: Implement edit profile dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de editar perfil en desarrollo')),
    );
  }

  void _navigateToReferrals() {
    // TODO: Navigate to referrals page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Referidos')),
    );
  }

  void _navigateToCommissions() {
    // TODO: Navigate to commissions page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Comisiones')),
    );
  }

  void _navigateToSupport() {
    // TODO: Navigate to support page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Soporte')),
    );
  }

  void _navigateToMarketingMaterials() {
    // TODO: Navigate to marketing materials page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a Materiales de Marketing')),
    );
  }
} 