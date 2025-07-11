import 'package:flutter/material.dart';

class AffiliateStatisticsPage extends StatefulWidget {
  const AffiliateStatisticsPage({super.key});

  @override
  State<AffiliateStatisticsPage> createState() => _AffiliateStatisticsPageState();
}

class _AffiliateStatisticsPageState extends State<AffiliateStatisticsPage> {
  String _selectedPeriod = 'Este Mes';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];
  String _selectedMetric = 'Ganancias';
  final List<String> _metrics = ['Ganancias', 'Referidos', 'Comisiones', 'Conversión'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.purple[700],
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
            // Period and Metric Selectors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Métrica: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMetric,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _metrics.map((metric) {
                            return DropdownMenuItem(value: metric, child: Text(metric));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMetric = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Key Performance Indicators
            const Text('Indicadores Clave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildKPICard('Ganancias Totales', '\$2,450', '+15%', Colors.green, Icons.attach_money),
                _buildKPICard('Referidos Activos', '24', '+8%', Colors.blue, Icons.people),
                _buildKPICard('Tasa de Conversión', '12.5%', '+2.3%', Colors.orange, Icons.trending_up),
                _buildKPICard('Comisiones Promedio', '\$18.50', '+5%', Colors.purple, Icons.percent),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Performance Chart
            const Text('Rendimiento en el Tiempo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildPerformanceChart(),
            
            const SizedBox(height: 24),
            
            // Top Performing Referrals
            const Text('Mejores Referidos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildTopReferralsCard(),
            
            const SizedBox(height: 24),
            
            // Conversion Analysis
            const Text('Análisis de Conversión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildConversionAnalysisCard(),
            
            const SizedBox(height: 24),
            
            // Geographic Performance
            const Text('Rendimiento Geográfico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildGeographicPerformanceCard(),
            
            const SizedBox(height: 24),
            
            // Comparison with Previous Period
            const Text('Comparación con Período Anterior', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildComparisonCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, String change, Color color, IconData icon) {
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

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evolución de Ganancias', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Simulated chart area
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Gráfico de Rendimiento',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Datos del período seleccionado',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegend('Ganancias', Colors.green),
                _buildChartLegend('Referidos', Colors.blue),
                _buildChartLegend('Comisiones', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTopReferralsCard() {
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
                final referrals = [
                  {'name': 'Juan Pérez', 'earnings': 450.00, 'referrals': 8, 'conversion': 85.0},
                  {'name': 'María González', 'earnings': 380.00, 'referrals': 6, 'conversion': 92.0},
                  {'name': 'Carlos Rodríguez', 'earnings': 320.00, 'referrals': 5, 'conversion': 78.0},
                  {'name': 'Ana Martínez', 'earnings': 280.00, 'referrals': 4, 'conversion': 88.0},
                  {'name': 'Luis Fernández', 'earnings': 250.00, 'referrals': 3, 'conversion': 75.0},
                ];
                
                final referral = referrals[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: Text(
                      referral['name']!.split(' ').map((e) => e[0]).join(''),
                      style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(referral['name']!),
                  subtitle: Text('${referral['referrals']} referidos • ${referral['conversion']}% conversión'),
                  trailing: Text(
                    '\$${referral['earnings']!.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionAnalysisCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Análisis de Conversión', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildConversionItem('Clicks en Enlace', '1,250', '100%'),
            _buildConversionItem('Visitas Registradas', '156', '12.5%'),
            _buildConversionItem('Registros Completados', '24', '15.4%'),
            _buildConversionItem('Primeras Compras', '18', '75.0%'),
            _buildConversionItem('Usuarios Activos', '15', '83.3%'),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu tasa de conversión está 2.3% por encima del promedio',
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

  Widget _buildConversionItem(String stage, String count, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(stage, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(count, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(
              rate,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicPerformanceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rendimiento por Región', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildRegionItem('Lima Metropolitana', '45%', '\$1,102', Colors.blue),
            _buildRegionItem('Arequipa', '18%', '\$441', Colors.green),
            _buildRegionItem('Trujillo', '12%', '\$294', Colors.orange),
            _buildRegionItem('Piura', '10%', '\$245', Colors.purple),
            _buildRegionItem('Otros', '15%', '\$368', Colors.grey),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lima Metropolitana es tu región de mejor rendimiento',
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

  Widget _buildRegionItem(String region, String percentage, String earnings, Color color) {
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
            child: Text(region, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(percentage, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Text(earnings, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comparación Período Anterior', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildComparisonItem('Ganancias', '\$2,450', '\$2,130', '+15.0%'),
            _buildComparisonItem('Referidos', '24', '18', '+33.3%'),
            _buildComparisonItem('Tasa de Conversión', '12.5%', '10.2%', '+22.5%'),
            _buildComparisonItem('Comisiones Promedio', '\$18.50', '\$17.60', '+5.1%'),
            
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
                      '¡Excelente crecimiento! Todos los indicadores muestran mejora',
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

  Widget _buildComparisonItem(String metric, String current, String previous, String change) {
    final isPositive = change.startsWith('+');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(metric, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(current, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(previous, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              change,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 