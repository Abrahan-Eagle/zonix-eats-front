import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
           
          
            // Listado de productos
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
                  // --- INICIO: TEMPLATE MODERNO SIN BARRA INFERIOR ---
                  return Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 11, 24, 0),
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            for (int i = 0; i < (products.length > 2 ? 2 : products.length); i++) ...[
                              if (i > 0) const SizedBox(width: 15),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0, 11, 0, 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navegación a detalles si se requiere
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        boxShadow: const [
                                          BoxShadow(
                                            blurRadius: 10,
                                            color: Colors.black12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: products[i].imagen != null
                                                  ? Image.network(
                                                      products[i].imagen!,
                                                      width: double.infinity,
                                                      height: 117,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      width: double.infinity,
                                                      height: 117,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.image, size: 48),
                                                    ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                products[i].nombre,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '\\${products[i].precio ?? '-'}',
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                                ),
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 15),
                                                    onPressed: () {
                                                      cartService.addToCart({
                                                        'id': products[i].id,
                                                        'nombre': products[i].nombre,
                                                        'precio': products[i].precio,
                                                      });
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Producto agregado al carrito')),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Si hay más productos, mostrar el resto en filas siguientes
                        if (products.length > 2)
                          ...List.generate(
                            ((products.length - 2) / 2).ceil(),
                            (row) {
                              final start = 2 + row * 2;
                              final end = (start + 2 > products.length) ? products.length : start + 2;
                              return Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    for (int i = start; i < end; i++) ...[
                                      if (i > start) const SizedBox(width: 15),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(0, 11, 0, 12),
                                          child: GestureDetector(
                                            onTap: () {
                                              // Navegación a detalles si se requiere
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).cardColor,
                                                boxShadow: const [
                                                  BoxShadow(
                                                    blurRadius: 10,
                                                    color: Colors.black12,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: products[i].imagen != null
                                                          ? Image.network(
                                                              products[i].imagen!,
                                                              width: double.infinity,
                                                              height: 117,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Container(
                                                              width: double.infinity,
                                                              height: 117,
                                                              color: Colors.grey.shade200,
                                                              child: const Icon(Icons.image, size: 48),
                                                            ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8),
                                                      child: Text(
                                                        products[i].nombre,
                                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          '\\${products[i].precio ?? '-'}',
                                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                                        ),
                                                        Container(
                                                          width: 30,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          alignment: Alignment.center,
                                                          child: IconButton(
                                                            icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 15),
                                                            onPressed: () {
                                                              cartService.addToCart({
                                                                'id': products[i].id,
                                                                'nombre': products[i].nombre,
                                                                'precio': products[i].precio,
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Producto agregado al carrito')),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                  // --- FIN: TEMPLATE MODERNO SIN BARRA INFERIOR ---
                },
              ),
<<<<<<< HEAD
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
=======
            ),
          ],
        ),
>>>>>>> mi-arreglo
      ),
    );
  }
}
