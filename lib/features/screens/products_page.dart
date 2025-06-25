import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay productos disponibles'));
          }
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(product['nombre'] ?? 'Sin nombre'),
                  subtitle: Text('Precio: \\${product['precio'] ?? '-'}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      cartService.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Producto agregado al carrito')),
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
