import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import 'product_detail_page.dart';

class ProductsPage extends StatefulWidget {
  final ProductService? productService;
  const ProductsPage({Key? key, this.productService}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _productsFuture;
  final Map<int, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = (widget.productService ?? ProductService()).fetchProducts();
  }

  void _incrementQuantity(int productId) {
    setState(() {
      _productQuantities[productId] = (_productQuantities[productId] ?? 1) + 1;
    });
  }

  void _decrementQuantity(int productId) {
    setState(() {
      if ((_productQuantities[productId] ?? 1) > 1) {
        _productQuantities[productId] = _productQuantities[productId]! - 1;
      }
    });
  }

  int _getQuantity(int productId) {
    return _productQuantities[productId] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ...aquí puedes agregar encabezado y buscador si lo deseas...
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _productsFuture = (widget.productService ?? ProductService()).fetchProducts();
                              });
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay productos disponibles'));
                  }
                  final products = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 11, 24, 0),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final quantity = _getQuantity(product.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(product: product),
                              ),
                            );
                          },
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _decrementQuantity(product.id),
                              ),
                              Text('$quantity'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _incrementQuantity(product.id),
                              ),
                            ],
                          ),
                          title: Text(product.nombre),
                          subtitle: Text('${product.precio ?? '-'} \$'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              cartService.addToCart(CartItem(
                                id: product.id,
                                nombre: product.nombre,
                                precio: product.precio,
                                quantity: quantity,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Producto agregado al carrito')),
                              );
                            },
                            child: const Text('Agregar'),
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
      ),
    );
  }
}
