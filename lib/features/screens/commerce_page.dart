import 'package:flutter/material.dart';
import 'commerce/commerce_dashboard_page.dart';
import 'commerce/commerce_orders_page.dart';
import 'commerce/commerce_products_page.dart';
import 'commerce/commerce_profile_page.dart';

class CommercePage extends StatefulWidget {
  const CommercePage({super.key});

  @override
  State<CommercePage> createState() => _CommercePageState();
}

class _CommercePageState extends State<CommercePage> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _error;

  final List<Widget> _pages = [
    const CommerceDashboardPage(),
    const CommerceOrdersPage(),
    const CommerceProductsPage(),
    const CommerceProfilePage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Órdenes',
    'Productos',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).pushNamed('/commerce/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/commerce/settings');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Órdenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 1: // Órdenes
        return FloatingActionButton(
          heroTag: 'commerce_page_orders_refresh',
          onPressed: () {
            // Refresh orders
            setState(() {
              _isLoading = true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              setState(() {
                _isLoading = false;
              });
            });
          },
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          child: const Icon(Icons.refresh),
        );
      case 2: // Productos
        return FloatingActionButton(
          heroTag: 'commerce_page_products_add',
          onPressed: () {
            Navigator.of(context).pushNamed('/commerce/products/create');
          },
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = false;
              });
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// Widget de estadísticas rápidas para el dashboard
class QuickStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const QuickStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Órdenes Hoy',
                    '${stats['orders_today'] ?? 0}',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ingresos Hoy',
                    '\$${(stats['revenue_today'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Productos Activos',
                    '${stats['active_products'] ?? 0}',
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Calificación',
                    '${(stats['average_rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Widget de acciones rápidas
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Nuevo Producto',
                    Icons.add_circle,
                    Colors.green,
                    () => Navigator.of(context).pushNamed('/commerce/products/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Ver Órdenes',
                    Icons.receipt,
                    Colors.blue,
                    () => Navigator.of(context).pushNamed('/commerce/orders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Promociones',
                    Icons.local_offer,
                    Colors.orange,
                    () => Navigator.of(context).pushNamed('/commerce/promotions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Reportes',
                    Icons.analytics,
                    Colors.purple,
                    () => Navigator.of(context).pushNamed('/commerce/reports'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
