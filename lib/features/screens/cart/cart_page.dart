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
        backgroundColor: Colors.grey[100],
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.notifications_none, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: cartItems.isEmpty
                    ? const Center(child: Text('El carrito está vacío'))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        color: Colors.grey[200],
                                        width: 80,
                                        height: 80,
                                        child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey[400]),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nombre,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Cantidad: ${item.quantity}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '₡${item.precio?.toStringAsFixed(2) ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
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
                                                    color: Color(0xFFE5E5E5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.remove_sharp, size: 15),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${item.quantity}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                                                    color: Colors.black,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.add, color: Colors.white, size: 15),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                          ),
                          Text(
                            '${cartItems.length}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 0.1, thickness: 1, color: Colors.black12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total a pagar:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ),
                          Text(
                            '₡${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
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
                      backgroundColor: Colors.black,
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
