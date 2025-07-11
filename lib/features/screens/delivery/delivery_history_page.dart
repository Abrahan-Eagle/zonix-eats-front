import 'package:flutter/material.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({Key? key}) : super(key: key);

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  bool _isLoading = true;
  String _selectedPeriod = 'Esta Semana';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];
  
  List<Map<String, dynamic>> _deliveryHistory = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos del historial
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _stats = {
          'totalDeliveries': 156,
          'totalEarnings': 125000.0,
          'averageRating': 4.8,
          'totalDistance': 450.5,
          'totalTime': 78.5,
          'onTimeDeliveries': 142,
          'lateDeliveries': 14,
        };
        
        _deliveryHistory = [
          {
            'id': 1,
            'orderNumber': 'ORD-001',
            'customerName': 'Juan Pérez',
            'address': 'San José, Costa Rica',
            'status': 'delivered',
            'total': 15000.0,
            'deliveryFee': 2000.0,
            'tip': 1000.0,
            'distance': 2.5,
            'time': 25,
            'rating': 5,
            'comment': 'Excelente servicio, muy rápido',
            'deliveredAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          },
          {
            'id': 2,
            'orderNumber': 'ORD-002',
            'customerName': 'María García',
            'address': 'Heredia, Costa Rica',
            'status': 'delivered',
            'total': 8500.0,
            'deliveryFee': 1500.0,
            'tip': 500.0,
            'distance': 1.8,
            'time': 18,
            'rating': 4,
            'comment': 'Buen servicio',
            'deliveredAt': DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          },
          {
            'id': 3,
            'orderNumber': 'ORD-003',
            'customerName': 'Carlos López',
            'address': 'Alajuela, Costa Rica',
            'status': 'delivered',
            'total': 22000.0,
            'deliveryFee': 2500.0,
            'tip': 2000.0,
            'distance': 3.2,
            'time': 35,
            'rating': 5,
            'comment': 'Muy amable y puntual',
            'deliveredAt': DateTime.now().subtract(const Duration(days: 2, hours: 1)),
          },
          {
            'id': 4,
            'orderNumber': 'ORD-004',
            'customerName': 'Ana Rodríguez',
            'address': 'Cartago, Costa Rica',
            'status': 'delivered',
            'total': 12000.0,
            'deliveryFee': 1800.0,
            'tip': 800.0,
            'distance': 4.1,
            'time': 42,
            'rating': 4,
            'comment': 'Llegó a tiempo',
            'deliveredAt': DateTime.now().subtract(const Duration(days: 2, hours: 3)),
          },
          {
            'id': 5,
            'orderNumber': 'ORD-005',
            'customerName': 'Luis Martínez',
            'address': 'San José, Costa Rica',
            'status': 'delivered',
            'total': 18000.0,
            'deliveryFee': 2000.0,
            'tip': 1500.0,
            'distance': 2.8,
            'time': 28,
            'rating': 5,
            'comment': 'Perfecto servicio',
            'deliveredAt': DateTime.now().subtract(const Duration(days: 3, hours: 2)),
          },
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historial: $e')),
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
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

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con número de orden y fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  delivery['orderNumber'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${delivery['deliveredAt'].day}/${delivery['deliveredAt'].month}/${delivery['deliveredAt'].year}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información del cliente
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  delivery['customerName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Dirección
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery['address'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Métricas de la entrega
            Row(
              children: [
                Expanded(
                  child: _buildDeliveryMetric(
                    'Distancia',
                    '${delivery['distance']} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildDeliveryMetric(
                    'Tiempo',
                    '${delivery['time']} min',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildDeliveryMetric(
                    'Calificación',
                    '${delivery['rating']}/5',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información financiera
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ₡${delivery['total'].toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Comisión: ₡${delivery['deliveryFee'].toStringAsFixed(0)}',
                          style: const TextStyle(
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
                        'Propina: ₡${delivery['tip'].toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Ganancia: ₡${(delivery['deliveryFee'] + delivery['tip']).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Comentario del cliente
            if (delivery['comment'] != null && delivery['comment'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          delivery['comment'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendimiento de Entregas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    'A tiempo',
                    _stats['onTimeDeliveries'],
                    _stats['totalDeliveries'],
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Tardías',
                    _stats['lateDeliveries'],
                    _stats['totalDeliveries'],
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 48,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gráfico de Rendimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Implementación futura',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String title, int value, int total, Color color) {
    double percentage = total > 0 ? (value / total) * 100 : 0;
    
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$value/$total',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          // Filtro de período
          PopupMenuButton<String>(
            onSelected: (String period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadHistoryData();
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
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistoryData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas principales
                    const Text(
                      'Resumen del Período',
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
                        _buildStatCard(
                          'Entregas',
                          '${_stats['totalDeliveries']}',
                          Icons.delivery_dining,
                          Colors.blue,
                          'Total realizadas',
                        ),
                        _buildStatCard(
                          'Ganancias',
                          '₡${_stats['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
                          Icons.attach_money,
                          Colors.green,
                          'Ingresos totales',
                        ),
                        _buildStatCard(
                          'Calificación',
                          '${_stats['averageRating']?.toStringAsFixed(1) ?? '0'}/5',
                          Icons.star,
                          Colors.amber,
                          'Promedio',
                        ),
                        _buildStatCard(
                          'Distancia',
                          '${_stats['totalDistance']?.toStringAsFixed(1) ?? '0'} km',
                          Icons.straighten,
                          Colors.purple,
                          'Total recorrida',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gráfico de rendimiento
                    _buildPerformanceChart(),
                    
                    const SizedBox(height: 24),
                    
                    // Historial de entregas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historial de Entregas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exportar historial')),
                            );
                          },
                          child: const Text('Exportar'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Lista de entregas
                    ..._deliveryHistory.map((delivery) => _buildDeliveryCard(delivery)),
                    
                    const SizedBox(height: 100), // Espacio para el FAB
                  ],
                ),
              ),
            ),
    );
  }
} 