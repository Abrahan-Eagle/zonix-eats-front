import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../features/services/commerce_promotion_service.dart';
import 'commerce_promotion_form_page.dart';

class CommercePromotionsPage extends StatefulWidget {
  const CommercePromotionsPage({Key? key}) : super(key: key);

  @override
  State<CommercePromotionsPage> createState() => _CommercePromotionsPageState();
}

class _CommercePromotionsPageState extends State<CommercePromotionsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _promotionsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  final List<String> _statusTabs = [
    'Todas',
    'Activas',
    'Inactivas',
    'Expiradas',
    'Próximas a Expirar',
  ];

  final Map<String, String> _statusFilters = {
    'Todas': '',
    'Activas': 'active',
    'Inactivas': 'inactive',
    'Expiradas': 'expired',
    'Próximas a Expirar': 'expiring_soon',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _promotionsFuture = CommercePromotionService.getPromotions(
        status: _statusFilters[_statusTabs[_tabController.index]],

        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _statsFuture = CommercePromotionService.getPromotionStats();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _loadData();
  }

  Future<void> _deletePromotion(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar promoción'),
        content: const Text('¿Estás seguro de que deseas eliminar esta promoción? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommercePromotionService.deletePromotion(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promoción eliminada correctamente'),
          backgroundColor: Colors.green,
        )
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar promoción: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _togglePromotionStatus(int id) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommercePromotionService.togglePromotionStatus(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado de promoción actualizado'),
          backgroundColor: Colors.green,
        )
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Promociones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['total_promotions'] ?? 0}',
                        Icons.local_offer,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Activas',
                        '${stats['active_promotions'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Inactivas',
                        '${stats['inactive_promotions'] ?? 0}',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Expiradas',
                        '${stats['expired_promotions'] ?? 0}',
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Usos Totales',
                        '${stats['total_uses'] ?? 0}',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Ingresos',
                        '\$${(stats['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar promociones',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() { _searchQuery = value; });
                _loadData();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ordenar por',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'created_at', child: Text('Fecha')),
                      DropdownMenuItem(value: 'title', child: Text('Título')),
                      DropdownMenuItem(value: 'discount_value', child: Text('Descuento')),
                      DropdownMenuItem(value: 'priority', child: Text('Prioridad')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortBy = value!; });
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Orden',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortOrder,
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Descendente')),
                      DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortOrder = value!; });
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final isActive = promotion['is_active'] ?? false;
    final discountType = promotion['discount_type'] ?? 'percentage';
    final discountValue = promotion['discount_value'] ?? 0.0;
    final startDate = DateTime.parse(promotion['start_date'] ?? DateTime.now().toIso8601String());
    final endDate = DateTime.parse(promotion['end_date'] ?? DateTime.now().toIso8601String());
    final isExpired = endDate.isBefore(DateTime.now());
    final isExpiringSoon = endDate.difference(DateTime.now()).inDays <= 7;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isActive ? Colors.green : Colors.grey,
                  child: promotion['image_url'] != null
                      ? ClipOval(
                          child: Image.network(
                            promotion['image_url'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_offer),
                          ),
                        )
                      : const Icon(Icons.local_offer, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion['title'] ?? 'Sin título',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isExpired ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(isActive, isExpired, isExpiringSoon),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(isActive, isExpired, isExpiringSoon),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Descripción
            Text(
              promotion['description'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            // Información de descuento y fechas
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: discountType == 'percentage' ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discountType == 'percentage' 
                        ? '${discountValue.toStringAsFixed(0)}%' 
                        : '\$${discountValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (promotion['minimum_order'] != null)
                  Text(
                    'Mín: \$${(promotion['minimum_order'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(startDate)} - ${_formatDate(endDate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  onPressed: _loading ? null : () => _togglePromotionStatus(promotion['id']),
                  tooltip: isActive ? 'Desactivar' : 'Activar',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _loading ? null : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommercePromotionFormPage(promotion: promotion),
                      ),
                    );
                    if (result == true) _refresh();
                  },
                  tooltip: 'Editar promoción',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _loading ? null : () => _deletePromotion(promotion['id']),
                  tooltip: 'Eliminar promoción',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(bool isActive, bool isExpired, bool isExpiringSoon) {
    if (isExpired) return Colors.red;
    if (isExpiringSoon) return Colors.orange;
    if (isActive) return Colors.green;
    return Colors.grey;
  }

  String _getStatusText(bool isActive, bool isExpired, bool isExpiringSoon) {
    if (isExpired) return 'Expirada';
    if (isExpiringSoon) return 'Expira Pronto';
    if (isActive) return 'Activa';
    return 'Inactiva';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Promociones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((tab) => Tab(text: tab)).toList(),
          onTap: (index) {
            _loadData();
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatsCard(),
              _buildFilters(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _promotionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar promociones',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_offer, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay promociones',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primera promoción para atraer clientes',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CommercePromotionFormPage(),
                                  ),
                                );
                                if (result == true) _refresh();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Promoción'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final promotions = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: promotions.length,
                        itemBuilder: (context, index) => _buildPromotionCard(promotions[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommercePromotionFormPage(),
            ),
          );
          if (result == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Promoción'),
        tooltip: 'Crear nueva promoción',
      ),
    );
  }
} 