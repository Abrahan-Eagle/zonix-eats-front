import 'package:flutter/material.dart';
import '../../../models/commerce_order.dart';
import '../../../services/commerce_order_service.dart';

class CommerceOrderDetailPage extends StatefulWidget {
  final int orderId;
  const CommerceOrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<CommerceOrderDetailPage> createState() => _CommerceOrderDetailPageState();
}

class _CommerceOrderDetailPageState extends State<CommerceOrderDetailPage> {
  late Future<CommerceOrder> _orderFuture;
  final CommerceOrderService _orderService = CommerceOrderService();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orderFuture = _orderService.fetchOrderDetail(widget.orderId);
  }

  Future<void> _updateStatus(String status) async {
    setState(() { _loading = true; _error = null; });
    try {
      await _orderService.updateOrderStatus(widget.orderId, status);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
      setState(() { _orderFuture = _orderService.fetchOrderDetail(widget.orderId); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Orden')),
      body: FutureBuilder<CommerceOrder>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No se encontró la orden'));
          }
          final order = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orden #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 12),
                Text('Estado: ${order.status}'),
                Text('Total: ${order.total.toStringAsFixed(2)}\$'),
                if (order.notes != null) Text('Notas: ${order.notes}'),
                const SizedBox(height: 16),
                const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Text('- ${item['product_name'] ?? ''} x${item['quantity'] ?? ''}')).toList(),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                if (_loading)
                  const CircularProgressIndicator()
                else
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateStatus('preparing'),
                        child: const Text('Preparando'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _updateStatus('delivered'),
                        child: const Text('Entregado'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
} 