import 'package:flutter/material.dart';
import 'package:zonix/models/order.dart';

class CommerceReportsPage extends StatefulWidget {
  const CommerceReportsPage({Key? key}) : super(key: key);

  @override
  State<CommerceReportsPage> createState() => _CommerceReportsPageState();
}

class _CommerceReportsPageState extends State<CommerceReportsPage> {
  bool _isLoading = true;
  String _selectedPeriod = 'Hoy';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];
  
  Map<String, dynamic> _salesData = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _salesByCategory = [];

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos de reportes
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _salesData = {
          'totalSales': 125000.0,
          'totalOrders': 45,
          'averageOrderValue': 2777.78,
          'growthRate': 12.5,
          'customerCount': 28,
          'repeatCustomers': 15,
        };
        
        _topProducts = [
          {'name': 'Hamburguesa Clásica', 'sales': 25000, 'quantity': 8},
          {'name': 'Pizza Margherita', 'sales': 18000, 'quantity': 4},
          {'name': 'Coca Cola', 'sales': 12000, 'quantity': 15},
          {'name': 'Papas Fritas', 'sales': 9000, 'quantity': 6},
          {'name': 'Tarta de Chocolate', 'sales': 6000, 'quantity': 5},
        ];
        
        _salesByCategory = [
          {'category': 'Comida', 'sales': 43000, 'percentage': 34.4},
          {'category': 'Bebidas', 'sales': 20000, 'percentage': 16.0},
          {'category': 'Snacks', 'sales': 9000, 'percentage': 7.2},
          {'category': 'Postres', 'sales': 6000, 'percentage': 4.8},
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar reportes: $e')),
      );
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
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

  Widget _buildTopProductsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos Más Vendidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._topProducts.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> product = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('${product['quantity']} unidades vendidas'),
                trailing: Text(
                  '\$${product['sales'].toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySalesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._salesByCategory.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            category['category'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '\$${category['sales'].toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${category['percentage'].toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: category['percentage'] / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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

  Widget _buildSalesChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendencia de Ventas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                      Icons.show_chart,
                      size: 48,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gráfico de Ventas',
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

  Widget _buildCustomerInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights de Clientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Clientes Totales',
                    '${_salesData['customerCount']}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    'Clientes Recurrentes',
                    '${_salesData['repeatCustomers']}',
                    Icons.repeat,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tasa de retención: ${((_salesData['repeatCustomers'] / _salesData['customerCount']) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
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

  Widget _buildInsightItem(String title, String value, IconData icon, Color color) {
    return Column(
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          // Filtro de período
          PopupMenuButton<String>(
            onSelected: (String period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadReportsData();
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
            onPressed: _loadReportsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Métricas principales
                    const Text(
                      'Resumen de Ventas',
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
                        _buildMetricCard(
                          'Ventas Totales',
                          '\$${_salesData['totalSales']?.toStringAsFixed(0) ?? '0'}',
                          Icons.attach_money,
                          Colors.green,
                          'Ingresos totales',
                        ),
                        _buildMetricCard(
                          'Órdenes',
                          '${_salesData['totalOrders'] ?? 0}',
                          Icons.shopping_cart,
                          Colors.blue,
                          'Total de pedidos',
                        ),
                        _buildMetricCard(
                          'Ticket Promedio',
                          '\$${_salesData['averageOrderValue']?.toStringAsFixed(0) ?? '0'}',
                          Icons.receipt,
                          Colors.orange,
                          'Por orden',
                        ),
                        _buildMetricCard(
                          'Crecimiento',
                          '${_salesData['growthRate']?.toStringAsFixed(1) ?? '0'}%',
                          Icons.trending_up,
                          Colors.purple,
                          'vs período anterior',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gráfico de ventas
                    _buildSalesChart(),
                    
                    const SizedBox(height: 24),
                    
                    // Productos más vendidos
                    _buildTopProductsCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Ventas por categoría
                    _buildCategorySalesCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Insights de clientes
                    _buildCustomerInsights(),
                    
                    const SizedBox(height: 24),
                    
                    // Botón para exportar reporte
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reporte exportado como PDF'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar Reporte'),
                        style: ElevatedButton.styleFrom(
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