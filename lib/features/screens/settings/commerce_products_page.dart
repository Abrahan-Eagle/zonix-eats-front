import 'package:flutter/material.dart';
import '../../../models/commerce_product.dart';
import '../../services/commerce_product_service.dart';

class CommerceProductsPage extends StatefulWidget {
  const CommerceProductsPage({super.key});

  @override
  State<CommerceProductsPage> createState() => _CommerceProductsPageState();
}

class _CommerceProductsPageState extends State<CommerceProductsPage> {
  late Future<List<CommerceProduct>> _productsFuture;
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProducts();
  }

  Future<void> _fetchCategoriesAndProducts() async {
    setState(() { _loadingCategories = true; });
    try {
      _categories = await CommerceProductService.getProductCategories();
    } catch (e) {
      _categories = [];
    } finally {
      setState(() { _loadingCategories = false; });
    }
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = CommerceProductService.getProducts();
    });
  }

  void _filterByCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _productsFuture = CommerceProductService.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos del comercio')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _loadingCategories
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('Todas las categorías')),
                      ..._categories.map((cat) => DropdownMenuItem<int>(
                            value: cat['id'],
                            child: Text(cat['name']),
                          ))
                    ],
                    onChanged: (value) {
                      _filterByCategory(value);
                    },
                    decoration: const InputDecoration(labelText: 'Filtrar por categoría'),
                  ),
          ),
          Expanded(
            child: FutureBuilder<List<CommerceProduct>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay productos disponibles'));
                }
                final products = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 11, 24, 0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${product.price.toStringAsFixed(2)} \$'),
                            if (product.category != null)
                              Text('Categoría: ${product.category}'),
                            if (product.stock != null)
                              Text('Stock: ${product.stock}'),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // TODO: Navegar a editar producto
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    // TODO: Eliminar producto
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a formulario de crear producto
        },
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
} 