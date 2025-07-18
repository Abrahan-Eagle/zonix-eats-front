import 'package:flutter/material.dart';
import 'dart:io';
import '../../../features/services/commerce_product_service.dart';
import '../../../models/commerce_product.dart';
import 'commerce_product_form_page.dart';
import '../../../features/services/commerce_data_service.dart';
import '../../../models/commerce_profile.dart';

class CommerceInventoryPage extends StatefulWidget {
  const CommerceInventoryPage({Key? key}) : super(key: key);

  @override
  State<CommerceInventoryPage> createState() => _CommerceInventoryPageState();
}

class _CommerceInventoryPageState extends State<CommerceInventoryPage> {
  late Future<List<CommerceProduct>> _productsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  bool _loading = false;
  String? _error;
  bool _open = true;
  String _searchQuery = '';
  bool _showOnlyAvailable = false;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _productsFuture = CommerceProductService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        available: _showOnlyAvailable ? true : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _statsFuture = CommerceProductService.getProductStats();
    });

    try {
      final commerceData = await CommerceDataService.getCommerceData();
      if (!mounted) return;
      setState(() { 
        _open = commerceData['open'] ?? true; 
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _open = true; });
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _loadData();
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto? Esta acción no se puede deshacer.'),
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
      await CommerceProductService.deleteProduct(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado correctamente'),
          backgroundColor: Colors.green,
        )
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar producto: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _toggleAvailability(CommerceProduct product) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceProductService.toggleAvailability(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(product.available ? 'Producto marcado como no disponible' : 'Producto marcado como disponible'),
          backgroundColor: Colors.green,
        )
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar disponibilidad: $e'),
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
                  'Estadísticas de Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['total_productos'] ?? 0}',
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Disponibles',
                        '${stats['productos_disponibles'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'No Disponibles',
                        '${stats['productos_no_disponibles'] ?? 0}',
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
                        'Precio Promedio',
                        '\$${(stats['precio_promedio'] ?? 0.0).toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Más Caro',
                        '\$${(stats['producto_mas_caro'] ?? 0.0).toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.purple,
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
                labelText: 'Buscar productos',
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
                  child: CheckboxListTile(
                    title: const Text('Solo disponibles'),
                    value: _showOnlyAvailable,
                    onChanged: (value) {
                      setState(() { _showOnlyAvailable = value ?? false; });
                      _loadData();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
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
                      DropdownMenuItem(value: 'price', child: Text('Precio')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortBy = value!; });
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

  Widget _buildProductCard(CommerceProduct product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.available ? Colors.green : Colors.grey,
          child: product.image != null
              ? ClipOval(
                  child: Image.network(
                    product.image!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood),
                  ),
                )
              : const Icon(Icons.fastfood, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: product.available ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 4),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                product.available ? Icons.check_circle : Icons.cancel,
                color: product.available ? Colors.green : Colors.red,
              ),
              onPressed: _loading ? null : () => _toggleAvailability(product),
              tooltip: product.available ? 'Marcar como no disponible' : 'Marcar como disponible',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _loading ? null : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommerceProductFormPage(product: product),
                  ),
                );
                if (result == true) _refresh();
              },
              tooltip: 'Editar producto',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _loading ? null : () => _deleteProduct(product.id),
              tooltip: 'Eliminar producto',
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommerceProductFormPage(product: product),
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
        title: const Text('Gestión de Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatsCard(),
              _buildFilters(),
              Expanded(
                child: FutureBuilder<List<CommerceProduct>>(
                  future: _productsFuture,
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
                              'Error al cargar productos',
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
                            const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega tu primer producto para comenzar',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _open ? () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CommerceProductFormPage(),
                                  ),
                                );
                                if (result == true) _refresh();
                              } : null,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Producto'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final products = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: products.length,
                        itemBuilder: (context, index) => _buildProductCard(products[index]),
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
        onPressed: !_open ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El comercio está cerrado. No puedes agregar productos.'),
              backgroundColor: Colors.orange,
            ),
          );
        } : () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommerceProductFormPage(),
            ),
          );
          if (result == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
        tooltip: 'Agregar nuevo producto',
      ),
    );
  }
} 