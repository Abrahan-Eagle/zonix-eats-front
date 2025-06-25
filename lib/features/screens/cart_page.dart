import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'package:provider/provider.dart';
import 'checkout_page.dart'; // Asegúrate de que la ruta de importación sea correcta
import '../../models/cart_item.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: cartItems.isEmpty
          ? const Center(child: Text('El carrito está vacío'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(item.nombre),
                    subtitle: Text('Precio: \\${item.precio ?? '-'}'),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (item.quantity > 1) {
                              cartService.removeFromCart(CartItem(
                                id: item.id,
                                nombre: item.nombre,
                                precio: item.precio,
                                quantity: item.quantity - 1,
                              ));
                            }
                          },
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            cartService.removeFromCart(item);
                            cartService.addToCart(CartItem(
                              id: item.id,
                              nombre: item.nombre,
                              precio: item.precio,
                              quantity: item.quantity + 1,
                            ));
                          },
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        cartService.removeFromCart(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto eliminado del carrito')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckoutPage()),
                  );
                },
                child: const Text('Finalizar compra'),
              ),
            )
          : null,
    );
  }
}
