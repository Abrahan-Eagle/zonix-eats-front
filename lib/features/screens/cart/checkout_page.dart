import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/cart_item.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _handleCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final cartService = Provider.of<CartService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    try {
      await orderService.createOrder(cartService.items.toList());
      cartService.clearCart();
      setState(() {
        _success = '¡Orden creada exitosamente!';
      });
    } catch (e) {
      setState(() {
        _error = 'Error al crear la orden';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;
    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + (item.precio ?? 0) * item.quantity);
    final tax = subtotal * 0.05; // ejemplo: 5% de impuestos
    final delivery = 0.0;
    final totalPayment = subtotal + tax + delivery;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de compra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: cartService.items.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(item.nombre),
                    subtitle: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: item.quantity > 1
                              ? () {
                            cartService.decrementQuantity(item);
                          }
                              : null,
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
                    trailing: Text('\$${(item.precio ?? 0) * item.quantity}'),
                  ),
                )).toList(),
              ),
            ),
            // Resumen de orden moderno
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Total de productos:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text('$totalItems', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Subtotal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text(subtotal.toStringAsFixed(2), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Impuesto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text(tax.toStringAsFixed(2), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Envío', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text(delivery.toStringAsFixed(2), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Divider(height: 0.1, thickness: 1),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Total a pagar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
                      ),
                      Text(totalPayment.toStringAsFixed(2), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_success != null) ...[
              Text(_success!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleCheckout,
                child: _loading ? const CircularProgressIndicator() : const Text('Confirmar compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
