import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/address_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/order_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = false;
  String? _error;
  String? _success;
  String _deliveryType = 'pickup';
  String? _selectedAddress;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await AddressService().getUserAddresses();
      setState(() {
        _addresses = list;
        if (_addresses.isNotEmpty && _selectedAddress == null) {
          final defaultAddr = _addresses.firstWhere(
            (a) => a['is_default'] == true,
            orElse: () => _addresses.first,
          );
          _selectedAddress = (defaultAddr['formatted_address'] as String?) ?? _formatAddressFromMap(defaultAddr);
        }
      });
    } catch (_) {
      // Sin direcciones guardadas
    }
  }

  String _formatAddressFromMap(Map<String, dynamic> addr) {
    final parts = <String>[];
    if (addr['address_line_1'] != null) parts.add(addr['address_line_1'].toString());
    if (addr['address_line_2'] != null && addr['address_line_2'].toString().isNotEmpty) {
      parts.add(addr['address_line_2'].toString());
    }
    if (addr['city'] != null) parts.add(addr['city'].toString());
    if (addr['state'] != null) parts.add(addr['state'].toString());
    if (addr['postal_code'] != null) parts.add(addr['postal_code'].toString());
    if (addr['country'] != null) parts.add(addr['country'].toString());
    return parts.join(', ');
  }

  Future<void> _handleCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final cartService = Provider.of<CartService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    try {
      String? deliveryAddress;
      if (_deliveryType == 'delivery') {
        deliveryAddress = _selectedAddress;
        if (deliveryAddress == null || deliveryAddress.trim().isEmpty) {
          setState(() {
            _error = 'Selecciona o agrega una dirección de entrega';
            _loading = false;
          });
          return;
        }
      }
      final deliveryFee = _deliveryType == 'delivery' ? 2.50 : 0.0;
      await orderService.createOrder(
        cartService.items.toList(),
        deliveryType: _deliveryType,
        deliveryAddress: deliveryAddress,
        deliveryFee: deliveryFee,
      );
      cartService.clearCart();
      setState(() {
        _success = '¡Orden creada exitosamente!';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
    final tax = 0.0;
    final delivery = _deliveryType == 'delivery' ? 2.50 : 0.0;
    final totalPayment = subtotal + tax + delivery;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Resumen de compra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...cartService.items.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(item.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Notas: ${item.notes}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: item.quantity > 1
                              ? () => cartService.decrementQuantity(item)
                              : null,
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => cartService.incrementQuantity(item),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Text('\$${((item.precio ?? 0) * item.quantity).toStringAsFixed(2)}'),
              ),
            )),
            const SizedBox(height: 16),
            const Text('Tipo de entrega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Recoger'),
                    value: 'pickup',
                    groupValue: _deliveryType,
                    onChanged: (v) => setState(() => _deliveryType = v ?? 'pickup'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Envío'),
                    value: 'delivery',
                    groupValue: _deliveryType,
                    onChanged: (v) => setState(() => _deliveryType = v ?? 'delivery'),
                  ),
                ),
              ],
            ),
            if (_deliveryType == 'delivery') ...[
              const SizedBox(height: 8),
              const Text('Dirección de entrega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_addresses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No tienes direcciones. Agrega una en tu perfil.'),
                  ),
                )
              else
                ..._addresses.map((addr) {
                  final formatted = addr['formatted_address'] as String? ?? _formatAddressFromMap(addr);
                  final isSelected = _selectedAddress == formatted;
                  return Card(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: ListTile(
                      title: Text(addr['name']?.toString() ?? 'Dirección'),
                      subtitle: Text(formatted),
                      trailing: isSelected ? const Icon(Icons.check_circle) : null,
                      onTap: () => setState(() => _selectedAddress = formatted),
                    ),
                  );
                }),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildSummaryRow('Total de productos:', '$totalItems'),
                  _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                  if (tax > 0) _buildSummaryRow('Impuesto', '\$${tax.toStringAsFixed(2)}'),
                  _buildSummaryRow('Envío', '\$${delivery.toStringAsFixed(2)}'),
                  const Divider(height: 24, thickness: 1),
                  _buildSummaryRow('Total a pagar:', '\$${totalPayment.toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 8),
              Text(_success!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleCheckout,
                child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isTotal ? Colors.green : null)),
          ),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: isTotal ? Colors.green : null)),
        ],
      ),
    );
  }
}
