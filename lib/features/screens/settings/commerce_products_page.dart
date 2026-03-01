import 'package:flutter/material.dart';
import '../../../models/commerce_product.dart';
import '../../services/commerce_product_service.dart';

class CommerceProductsPage extends StatefulWidget {
  const CommerceProductsPage({super.key});

  @override
  State<CommerceProductsPage> createState() => _CommerceProductsPageState();
}

class _CommerceProductsPageState extends State<CommerceProductsPage> {
  List<CommerceProduct> _products = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = false;
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 300;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _currentPage >= _lastPage || _products.isEmpty) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
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
    _loadProducts(reset: true);
  }

  Future<void> _loadProducts({bool reset = true}) async {
    final pageToLoad = reset ? 1 : _currentPage + 1;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _products = [];
      });
    }
    try {
      final result = await CommerceProductService.getProductsPage(
        page: pageToLoad,
        perPage: 15,
      );
      setState(() {
        _products = reset ? result.products : [..._products, ...result.products];
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() { _loadingMore = true; });
    await _loadProducts(reset: false);
  }

  void _filterByCategory(int? categoryId) {
    setState(() { _selectedCategoryId = categoryId; });
    _loadProducts(reset: true);
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
            child: _loading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => _loadProducts(reset: true),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? const Center(child: Text('No hay productos disponibles'))
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 11, 24, 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 15,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _products.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _products.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              final product = _products[index];
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
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'settings_commerce_products_add',
        onPressed: () {
          // TODO: Navegar a formulario de crear producto
        },
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
} 