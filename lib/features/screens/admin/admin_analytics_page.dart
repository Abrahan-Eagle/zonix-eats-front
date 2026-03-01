import 'package:flutter/material.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  String _selectedPeriod = 'Últimos 7 días';
  final List<String> _periods = ['Hoy', 'Últimos 7 días', 'Último mes', 'Último trimestre', 'Último año'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas del Sistema'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _exportAnalytics();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshAnalytics();
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
                      initialValue: _selectedPeriod,
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
            
            // Key Metrics
            const Text('Métricas Clave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildMetricCard('Ingresos Totales', '\$125,430', '+18%', Colors.green, Icons.attach_money),
                _buildMetricCard('Órdenes Completadas', '2,847', '+12%', Colors.blue, Icons.shopping_cart),
                _buildMetricCard('Usuarios Activos', '8,234', '+8%', Colors.orange, Icons.people),
                _buildMetricCard('Tasa de Conversión', '3.2%', '+5%', Colors.purple, Icons.trending_up),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // User Analytics
            const Text('Analíticas de Usuarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildUserAnalyticsCard(),
            
            const SizedBox(height: 24),
            
            // Order Analytics
            const Text('Analíticas de Órdenes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildOrderAnalyticsCard(),
            
            const SizedBox(height: 24),
            
            // Revenue Analytics
            const Text('Analíticas de Ingresos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildRevenueAnalyticsCard(),
            
            const SizedBox(height: 24),
            
            // Performance Analytics
            const Text('Rendimiento del Sistema', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildPerformanceAnalyticsCard(),
            
            const SizedBox(height: 24),
            
            // Geographic Analytics
            const Text('Analíticas Geográficas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildGeographicAnalyticsCard(),
            
            const SizedBox(height: 24),
            
            // Top Performers
            const Text('Mejores Desempeños', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildTopPerformersCard(),
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
                color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
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

  Widget _buildUserAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crecimiento de Usuarios', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAnalyticsRow('Nuevos Registros', '1,234', '+15%'),
            _buildAnalyticsRow('Usuarios Activos', '8,234', '+8%'),
            _buildAnalyticsRow('Usuarios Retenidos', '6,789', '+12%'),
            _buildAnalyticsRow('Tasa de Abandono', '2.1%', '-5%'),
            _buildAnalyticsRow('Tiempo Promedio de Sesión', '24 min', '+3%'),
            _buildAnalyticsRow('Frecuencia de Uso', '3.2 veces/semana', '+7%'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crecimiento saludable de usuarios. Retención mejorando.',
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

  Widget _buildOrderAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Métricas de Órdenes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAnalyticsRow('Órdenes Totales', '2,847', '+12%'),
            _buildAnalyticsRow('Órdenes Completadas', '2,654', '+11%'),
            _buildAnalyticsRow('Órdenes Canceladas', '193', '-8%'),
            _buildAnalyticsRow('Tiempo Promedio de Entrega', '32 min', '-5%'),
            _buildAnalyticsRow('Valor Promedio de Orden', '\$44.20', '+6%'),
            _buildAnalyticsRow('Tasa de Satisfacción', '4.6/5', '+2%'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showOrderDetails();
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('Ver Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showOrderTrends();
                    },
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Tendencias'),
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

  Widget _buildRevenueAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Análisis de Ingresos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAnalyticsRow('Ingresos Totales', '\$125,430', '+18%'),
            _buildAnalyticsRow('Ingresos por Comisión', '\$12,543', '+15%'),
            _buildAnalyticsRow('Ingresos por Publicidad', '\$8,234', '+22%'),
            _buildAnalyticsRow('Ingresos por Suscripciones', '\$3,456', '+8%'),
            _buildAnalyticsRow('Margen de Beneficio', '23.4%', '+3%'),
            _buildAnalyticsRow('Costo por Adquisición', '\$12.50', '-5%'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crecimiento sólido de ingresos. Todas las fuentes en aumento.',
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

  Widget _buildPerformanceAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rendimiento del Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAnalyticsRow('Tiempo de Respuesta API', '120ms', '-10%'),
            _buildAnalyticsRow('Tasa de Éxito', '99.8%', '+0.1%'),
            _buildAnalyticsRow('Uso de CPU', '45%', '-5%'),
            _buildAnalyticsRow('Uso de Memoria', '68%', '-2%'),
            _buildAnalyticsRow('Conexiones Activas', '1,234', '+8%'),
            _buildAnalyticsRow('Errores por Hora', '2', '-50%'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPerformanceDetails();
                    },
                    icon: const Icon(Icons.speed),
                    label: const Text('Métricas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showSystemHealth();
                    },
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('Salud'),
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

  Widget _buildGeographicAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribución Geográfica', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildGeographicItem('Lima', '45%', '5,234 usuarios'),
            _buildGeographicItem('Arequipa', '18%', '2,123 usuarios'),
            _buildGeographicItem('Trujillo', '12%', '1,456 usuarios'),
            _buildGeographicItem('Piura', '8%', '987 usuarios'),
            _buildGeographicItem('Cusco', '6%', '734 usuarios'),
            _buildGeographicItem('Otros', '11%', '1,234 usuarios'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cobertura en 15 ciudades principales. Expansión planificada.',
                      style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold),
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

  Widget _buildGeographicItem(String city, String percentage, String users) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(city, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(percentage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(users, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mejores Desempeños', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildTopPerformerItem('Pizza Express', 'Comercio', '156 órdenes', '\$2,340'),
            _buildTopPerformerItem('Juan Pérez', 'Delivery', '89 entregas', '\$890'),
            _buildTopPerformerItem('Transporte Rápido', 'Transporte', '67 viajes', '\$1,230'),
            _buildTopPerformerItem('María González', 'Afiliado', '45 referidos', '\$450'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTopPerformers();
                    },
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('Ver Ranking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showRewards();
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Recompensas'),
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

  Widget _buildTopPerformerItem(String name, String type, String metric, String revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red[100],
            child: Text(
              name[0],
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(metric, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(revenue, style: TextStyle(color: Colors.green[700], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String metric, String value, String change) {
    final isPositive = change.startsWith('+');
    
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Analíticas'),
        content: const Text('¿En qué formato deseas exportar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analíticas exportadas como PDF')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('PDF', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analíticas exportadas como Excel')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Excel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _refreshAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analíticas actualizadas')),
    );
  }

  void _showOrderDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Órdenes'),
        content: const Text('Mostrando análisis detallado de órdenes'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showOrderTrends() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tendencias de Órdenes'),
        content: const Text('Mostrando tendencias y patrones'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPerformanceDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Métricas de Rendimiento'),
        content: const Text('Mostrando métricas detalladas del sistema'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSystemHealth() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salud del Sistema'),
        content: const Text('Mostrando estado de salud del sistema'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showTopPerformers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ranking de Desempeño'),
        content: const Text('Mostrando ranking completo de mejores desempeños'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showRewards() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sistema de Recompensas'),
        content: const Text('Gestionar recompensas para mejores desempeños'),
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