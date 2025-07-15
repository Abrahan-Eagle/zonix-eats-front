import 'package:flutter/material.dart';
import '../../../services/commerce_product_service.dart';
import '../../../models/commerce_product.dart';
import 'commerce_product_form_page.dart'; // Added import for CommerceProductFormPage
import '../../../services/commerce_profile_service.dart';
import '../../../models/commerce_profile.dart';

class CommerceInventoryPage extends StatefulWidget {
  const CommerceInventoryPage({Key? key}) : super(key: key);

  @override
  State<CommerceInventoryPage> createState() => _CommerceInventoryPageState();
}

class _CommerceInventoryPageState extends State<CommerceInventoryPage> {
  final CommerceProductService _productService = CommerceProductService();
  final CommerceProfileService _profileService = CommerceProfileService();
  late Future<List<CommerceProduct>> _productsFuture;
  bool _loading = false;
  String? _error;
  bool _open = true;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.fetchProducts();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetchProfile();
      if (!mounted) return;
      setState(() { _open = profile.open; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _open = true; });
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _productsFuture = _productService.fetchProducts();
    });
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _productService.deleteProduct(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      _refresh();
    } catch (e) {
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $_error')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de Productos')),
      body: Stack(
        children: [
          FutureBuilder<List<CommerceProduct>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay productos en inventario'));
              }
              final products = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.fastfood),
                        title: Text(product.name),
                        subtitle: Text('Precio: ${product.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(product.available ? Icons.check_circle : Icons.cancel, color: product.available ? Colors.green : Colors.red),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _loading ? null : () => _deleteProduct(product.id),
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
                  },
                ),
              );
            },
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !_open ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El comercio está cerrado. No puedes agregar productos.')),
          );
        } : () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommerceProductFormPage(),
            ),
          );
          if (result == true) _refresh();
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar producto',
      ),
    );
  }
} 