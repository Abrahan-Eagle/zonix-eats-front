import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _productsFuture;
  final Map<int, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().fetchProducts();
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
      appBar: AppBar(title: const Text('Productos')),
      body: FutureBuilder<List<Product>>(
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
                  Text('Error: \\${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _productsFuture = ProductService().fetchProducts();
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
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final quantity = _getQuantity(product.id);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(product.nombre),
                  subtitle: Text('Precio: \\${product.precio ?? '-'}'),
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
    );
  }
}
