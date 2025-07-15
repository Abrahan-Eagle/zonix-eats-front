import 'package:flutter/material.dart';

class DeliveryEarningsPage extends StatefulWidget {
  const DeliveryEarningsPage({Key? key}) : super(key: key);

  @override
  State<DeliveryEarningsPage> createState() => _DeliveryEarningsPageState();
}

class _DeliveryEarningsPageState extends State<DeliveryEarningsPage> {
  bool _isLoading = true;
  String _selectedPeriod = 'Esta Semana';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];
  
  Map<String, dynamic> _earningsData = {};
  List<Map<String, dynamic>> _earningsHistory = [];
  List<Map<String, dynamic>> _topEarningDays = [];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos de ganancias
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _earningsData = {
          'totalEarnings': 125000.0,
          'deliveryFees': 85000.0,
          'tips': 40000.0,
          'totalDeliveries': 156,
          'averagePerDelivery': 801.28,
          'averagePerHour': 2500.0,
          'totalHours': 50.0,
          'growthRate': 15.5,
          'goalProgress': 78.5,
        };
        
        _earningsHistory = [
          {
            'date': DateTime.now().subtract(const Duration(days: 1)),
            'earnings': 8500.0,
            'deliveries': 12,
            'hours': 8.5,
            'tips': 2500.0,
          },
          {
            'date': DateTime.now().subtract(const Duration(days: 2)),
            'earnings': 7200.0,
            'deliveries': 10,
            'hours': 7.0,
            'tips': 1800.0,
          },
          {
            'date': DateTime.now().subtract(const Duration(days: 3)),
            'earnings': 6800.0,
            'deliveries': 9,
            'hours': 6.5,
            'tips': 1500.0,
          },
          {
            'date': DateTime.now().subtract(const Duration(days: 4)),
            'earnings': 9200.0,
            'deliveries': 14,
            'hours': 9.0,
            'tips': 3200.0,
          },
          {
            'date': DateTime.now().subtract(const Duration(days: 5)),
            'earnings': 7800.0,
            'deliveries': 11,
            'hours': 7.5,
            'tips': 2100.0,
          },
        ];
        
        _topEarningDays = [
          {
            'date': 'Lunes',
            'earnings': 9200.0,
            'deliveries': 14,
            'color': Colors.blue,
          },
          {
            'date': 'Martes',
            'earnings': 8500.0,
            'deliveries': 12,
            'color': Colors.green,
          },
          {
            'date': 'Miércoles',
            'earnings': 7800.0,
            'deliveries': 11,
            'color': Colors.orange,
          },
          {
            'date': 'Jueves',
            'earnings': 7200.0,
            'deliveries': 10,
            'color': Colors.purple,
          },
          {
            'date': 'Viernes',
            'earnings': 6800.0,
            'deliveries': 9,
            'color': Colors.red,
          },
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ganancias: $e')),
      );
    }
  }

  Widget _buildEarningsCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desglose de Ganancias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Comisiones de entrega
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comisiones',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${_earningsData['deliveryFees']?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Propinas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${_earningsData['tips']?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Gráfico de dona
            Container(
              height: 150,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _earningsData['tips'] / _earningsData['totalEarnings'],
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${_earningsData['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Comisiones'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Propinas'),
                          ],
                        ),
                      ],
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

  Widget _buildTopEarningDaysCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mejores Días',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._topEarningDays.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> day = entry.value;
              double percentage = day['earnings'] / _earningsData['totalEarnings'] * 100;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: day['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day['date'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${day['deliveries']} entregas',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${day['earnings'].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: day['color'],
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meta Semanal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${_earningsData['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'de \$160,000',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_earningsData['goalProgress']?.toStringAsFixed(1) ?? '0'}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Completado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: _earningsData['goalProgress'] / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Faltan \$${(160000 - _earningsData['totalEarnings']).toStringAsFixed(0)} para alcanzar la meta',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de Ganancias',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ver historial completo')),
                    );
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ..._earningsHistory.map((day) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day['date'].day}/${day['date'].month}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${day['deliveries']} entregas • ${day['hours']} horas',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${day['earnings'].toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '\$${day['tips'].toStringAsFixed(0)} en propinas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganancias'),
        actions: [
          // Filtro de período
          PopupMenuButton<String>(
            onSelected: (String period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadEarningsData();
            },
            itemBuilder: (BuildContext context) {
              return _periods.map((String period) {
                return PopupMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEarningsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas principales
                    const Text(
                      'Resumen de Ganancias',
                      style: TextStyle(
                        fontSize: 20,
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
                      childAspectRatio: 1.3,
                      children: [
                        _buildEarningsCard(
                          'Ganancias',
                          '\$${_earningsData['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
                          Icons.attach_money,
                          Colors.green,
                          'Total del período',
                        ),
                        _buildEarningsCard(
                          'Entregas',
                          '${_earningsData['totalDeliveries']}',
                          Icons.delivery_dining,
                          Colors.blue,
                          'Total realizadas',
                        ),
                        _buildEarningsCard(
                          'Promedio',
                          '\$${_earningsData['averagePerDelivery']?.toStringAsFixed(0) ?? '0'}',
                          Icons.analytics,
                          Colors.orange,
                          'Por entrega',
                        ),
                        _buildEarningsCard(
                          'Por Hora',
                          '\$${_earningsData['averagePerHour']?.toStringAsFixed(0) ?? '0'}',
                          Icons.access_time,
                          Colors.purple,
                          'Promedio',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Desglose de ganancias
                    _buildEarningsBreakdown(),
                    
                    const SizedBox(height: 24),
                    
                    // Meta semanal
                    _buildGoalProgressCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Mejores días
                    _buildTopEarningDaysCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Historial de ganancias
                    _buildEarningsHistoryCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Botón para solicitar pago
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Solicitud de pago enviada'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Solicitar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Espacio para el FAB
                  ],
                ),
              ),
            ),
    );
  }
} 