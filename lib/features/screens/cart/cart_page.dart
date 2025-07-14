import 'package:flutter/material.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/cart/checkout_page.dart';
import 'package:zonix/models/cart_item.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;
    final total = cartItems.fold<double>(0, (sum, item) => sum + (item.precio ?? 0) * item.quantity);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    width: double.infinity,
                    child: Text(
                      'Carrito',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(1, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, right: 24),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.notifications_none, size: 24, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(child: Text('El carrito está vacío', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        color: Theme.of(context).colorScheme.surface,
                                        width: 80,
                                        height: 80,
                                        child: Icon(Icons.shopping_bag, size: 40, color: Theme.of(context).iconTheme.color?.withOpacity(0.2)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nombre,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Cantidad: ${item.quantity}',
                                            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '₡${item.precio?.toStringAsFixed(2) ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.greenAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  cartService.decrementQuantity(item);
                                                },
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF23262B),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.remove_sharp, size: 15, color: Colors.white54),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${item.quantity}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                              ),
                                              const SizedBox(width: 12),
                                              InkWell(
                                                onTap: () {
                                                  cartService.removeFromCart(item);
                                                  cartService.addToCart(CartItem(
                                                    id: item.id,
                                                    nombre: item.nombre,
                                                    precio: item.precio,
                                                    quantity: item.quantity + 1,
                                                  ));
                                                },
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.blueAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.add, color: Colors.white, size: 15),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                onPressed: () {
                                                  cartService.removeFromCart(item);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Producto eliminado del carrito')),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (cartItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 0, 0),
                  child: Text(
                    'Resumen de orden',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Items:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white54),
                            ),
                          ),
                          Text(
                            '${cartItems.length}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 0.1, thickness: 1, color: Colors.white12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total a pagar:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          Text(
                            '₡${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: cartItems.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 13, 24, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CheckoutPage()),
                      );
                    },
                    child: const Text(
                      'Finalizar compra',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
