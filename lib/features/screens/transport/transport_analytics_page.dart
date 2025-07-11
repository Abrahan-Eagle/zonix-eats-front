import 'package:flutter/material.dart';

class TransportAnalyticsPage extends StatefulWidget {
  const TransportAnalyticsPage({super.key});

  @override
  State<TransportAnalyticsPage> createState() => _TransportAnalyticsPageState();
}

class _TransportAnalyticsPageState extends State<TransportAnalyticsPage> {
  String _selectedPeriod = 'Esta Semana';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas de Transporte'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte descargado')),
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
            
            // Key Metrics
            const Text('Métricas Principales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard('Pedidos Completados', '156', Icons.check_circle, Colors.green),
                _buildMetricCard('Tiempo Promedio', '23 min', Icons.access_time, Colors.blue),
                _buildMetricCard('Conductores Activos', '8', Icons.people, Colors.orange),
                _buildMetricCard('Ingresos', '\$2,450', Icons.attach_money, Colors.purple),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Performance Charts
            const Text('Rendimiento por Conductor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildDriverPerformanceCard(),
            
            const SizedBox(height: 24),
            
            // Route Analytics
            const Text('Analíticas de Rutas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildRouteAnalyticsCard(),
            
            const SizedBox(height: 24),
            
            // Efficiency Metrics
            const Text('Métricas de Eficiencia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildEfficiencyMetricsCard(),
            
            const SizedBox(height: 24),
            
            // Top Performing Areas
            const Text('Zonas de Mejor Rendimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildTopAreasCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildDriverPerformanceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                final drivers = [
                  {'name': 'Carlos Rodríguez', 'orders': 45, 'rating': 4.8, 'time': '18 min'},
                  {'name': 'María González', 'orders': 38, 'rating': 4.9, 'time': '22 min'},
                  {'name': 'Luis Fernández', 'orders': 32, 'rating': 4.7, 'time': '25 min'},
                  {'name': 'Ana Martínez', 'orders': 28, 'rating': 4.6, 'time': '27 min'},
                  {'name': 'Pedro López', 'orders': 25, 'rating': 4.5, 'time': '29 min'},
                ];
                
                final driver = drivers[index];
                final name = driver['name'] as String;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      name.split(' ').map((e) => e[0]).join(''),
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('${driver['orders']} pedidos • ${driver['time']} promedio'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('${driver['rating']}'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteAnalyticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rutas Más Eficientes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildRouteItem('Centro → Norte', '12.5 km', '18 min', '95%'),
            _buildRouteItem('Sur → Este', '8.2 km', '15 min', '92%'),
            _buildRouteItem('Oeste → Centro', '10.1 km', '20 min', '88%'),
            _buildRouteItem('Norte → Sur', '15.3 km', '28 min', '85%'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Eficiencia promedio: 90% (↑ 5% vs semana anterior)',
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

  Widget _buildRouteItem(String route, String distance, String time, String efficiency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(route, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(distance, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(time, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(
              efficiency,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: double.parse(efficiency.replaceAll('%', '')) > 90 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyMetricsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Indicadores de Eficiencia', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildEfficiencyItem('Tiempo de Respuesta', '2.3 min', 'Excelente'),
            _buildEfficiencyItem('Tasa de Cancelación', '3.2%', 'Buena'),
            _buildEfficiencyItem('Satisfacción del Cliente', '4.7/5', 'Excelente'),
            _buildEfficiencyItem('Utilización de Flota', '78%', 'Buena'),
            _buildEfficiencyItem('Combustible por Pedido', '0.8L', 'Eficiente'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Rendimiento superior al promedio del sector!',
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

  Widget _buildEfficiencyItem(String metric, String value, String status) {
    Color statusColor;
    switch (status) {
      case 'Excelente':
        statusColor = Colors.green;
        break;
      case 'Buena':
        statusColor = Colors.blue;
        break;
      case 'Eficiente':
        statusColor = Colors.orange;
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

  Widget _buildTopAreasCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zonas de Alto Rendimiento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildAreaItem('Centro Comercial Plaza', '45 pedidos', '4.9★'),
            _buildAreaItem('Zona Universitaria', '38 pedidos', '4.8★'),
            _buildAreaItem('Parque Industrial', '32 pedidos', '4.7★'),
            _buildAreaItem('Residencial Norte', '28 pedidos', '4.6★'),
            _buildAreaItem('Centro Histórico', '25 pedidos', '4.5★'),
            
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
                      'Estas zonas generan el 65% de nuestros ingresos',
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

  Widget _buildAreaItem(String area, String orders, String rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(orders, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }
} 