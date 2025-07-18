import 'package:flutter/material.dart';
import '../../../features/services/commerce_delivery_zone_service.dart';
import 'commerce_delivery_zone_form_page.dart';

class CommerceDeliveryZonesPage extends StatefulWidget {
  const CommerceDeliveryZonesPage({Key? key}) : super(key: key);

  @override
  State<CommerceDeliveryZonesPage> createState() => _CommerceDeliveryZonesPageState();
}

class _CommerceDeliveryZonesPageState extends State<CommerceDeliveryZonesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _zonesFuture;
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
  ];

  final Map<String, String> _statusFilters = {
    'Todas': '',
    'Activas': 'active',
    'Inactivas': 'inactive',
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
      _zonesFuture = CommerceDeliveryZoneService.getDeliveryZones(
        status: _statusFilters[_statusTabs[_tabController.index]],
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _statsFuture = CommerceDeliveryZoneService.getDeliveryZoneStats();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _loadData();
  }

  Future<void> _deleteZone(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar zona'),
        content: const Text('¿Estás seguro de que deseas eliminar esta zona de delivery? Esta acción no se puede deshacer.'),
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
      await CommerceDeliveryZoneService.deleteDeliveryZone(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zona eliminada correctamente'),
          backgroundColor: Colors.green,
        )
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar zona: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _toggleZoneStatus(int id) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceDeliveryZoneService.toggleDeliveryZoneStatus(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado de zona actualizado'),
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
                  'Resumen de Zonas de Delivery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['total_zones'] ?? 0}',
                        Icons.location_on,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Activas',
                        '${stats['active_zones'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Inactivas',
                        '${stats['inactive_zones'] ?? 0}',
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
                        'Cobertura',
                        '${(stats['total_coverage_km'] ?? 0.0).toStringAsFixed(1)} km',
                        Icons.map,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Pedidos',
                        '${stats['total_orders'] ?? 0}',
                        Icons.local_shipping,
                        Colors.orange,
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
                labelText: 'Buscar zonas',
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
                      DropdownMenuItem(value: 'name', child: Text('Nombre')),
                      DropdownMenuItem(value: 'delivery_fee', child: Text('Tarifa')),
                      DropdownMenuItem(value: 'radius', child: Text('Radio')),
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

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final isActive = zone['is_active'] ?? false;
    final deliveryFee = (zone['delivery_fee'] is String)
        ? double.tryParse(zone['delivery_fee']) ?? 0.0
        : (zone['delivery_fee'] ?? 0.0).toDouble();
    final radius = (zone['radius'] is String)
        ? double.tryParse(zone['radius']) ?? 0.0
        : (zone['radius'] ?? 0.0).toDouble();
    final deliveryTime = zone['delivery_time'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: const Icon(Icons.location_on, color: Colors.white),
        ),
        title: Text(
          zone['name'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zone['description'] ?? 'Sin descripción'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${radius.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deliveryTime} min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (zone['center'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Centro: ${zone['center']['lat']?.toStringAsFixed(4)}, ${zone['center']['lng']?.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Activa' : 'Inactiva',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  onPressed: _loading ? null : () => _toggleZoneStatus(zone['id']),
                  tooltip: isActive ? 'Desactivar' : 'Activar',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _loading ? null : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommerceDeliveryZoneFormPage(zone: zone),
                      ),
                    );
                    if (result == true) _refresh();
                  },
                  tooltip: 'Editar zona',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _loading ? null : () => _deleteZone(zone['id']),
                  tooltip: 'Eliminar zona',
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommerceDeliveryZoneFormPage(zone: zone),
            ),
          );
          if (result == true) _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas de Delivery'),
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
                  future: _zonesFuture,
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
                              'Error al cargar zonas',
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
                            const Icon(Icons.location_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay zonas de delivery',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primera zona para definir áreas de entrega',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CommerceDeliveryZoneFormPage(),
                                  ),
                                );
                                if (result == true) _refresh();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Zona'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final zones = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: zones.length,
                        itemBuilder: (context, index) => _buildZoneCard(zones[index]),
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
              builder: (context) => const CommerceDeliveryZoneFormPage(),
            ),
          );
          if (result == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Zona'),
        tooltip: 'Crear nueva zona de delivery',
      ),
    );
  }
} 