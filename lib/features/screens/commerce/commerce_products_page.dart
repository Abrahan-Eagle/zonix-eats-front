import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zonix/models/commerce_product.dart';
import 'package:zonix/features/services/commerce_product_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';

class CommerceProductsPage extends StatefulWidget {
  const CommerceProductsPage({super.key});

  @override
  State<CommerceProductsPage> createState() => _CommerceProductsPageState();
}

class _CommerceProductsPageState extends State<CommerceProductsPage> {
  List<CommerceProduct> _products = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _filterAvailableOnly = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        _loadProducts();
      });
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await CommerceProductService.getProducts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        available: _filterAvailableOnly ? true : null,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(CommerceProduct product) async {
    try {
      await CommerceProductService.toggleAvailability(product.id);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product.available ? 'Producto desactivado' : 'Producto activado',
            ),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(CommerceProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await CommerceProductService.deleteProduct(product.id);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base$path' : '$base/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: Icon(
              _filterAvailableOnly ? Icons.filter_list : Icons.filter_list_off,
              color: _filterAvailableOnly ? AppColors.orange : null,
            ),
            onPressed: () {
              setState(() {
                _filterAvailableOnly = !_filterAvailableOnly;
                _loadProducts();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/commerce/products/create'),
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 64, color: AppColors.gray),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay productos',
                    style: TextStyle(fontSize: 18, color: AppColors.gray),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/commerce/products/create',
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar producto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: product.image != null && product.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageUrl(product.image),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant,
                          size: 40,
                        ),
                      ),
                    )
                  : const Icon(Icons.restaurant, size: 40),
              title: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  decoration: product.available ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                '\$${product.price.toStringAsFixed(2)}${product.available ? '' : ' · No disponible'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: product.available,
                    onChanged: (_) => _toggleAvailability(product),
                    activeThumbColor: AppColors.green,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        Navigator.pushNamed(
                          context,
                          '/commerce/products/${product.id}',
                          arguments: product,
                        );
                      } else if (v == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => Navigator.pushNamed(
                context,
                '/commerce/products/${product.id}',
                arguments: product,
              ),
            ),
          );
        },
      ),
    );
  }
}
