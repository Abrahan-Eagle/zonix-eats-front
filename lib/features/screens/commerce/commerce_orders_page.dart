import 'package:flutter/material.dart';
import '../../../services/commerce_order_service.dart';
import '../../../models/commerce_order.dart';
import 'commerce_order_detail_page.dart';

class CommerceOrdersPage extends StatefulWidget {
  final CommerceOrderService? orderService;
  final List<CommerceOrder>? initialOrders;
  const CommerceOrdersPage({Key? key, this.orderService, this.initialOrders}) : super(key: key);

  @override
  State<CommerceOrdersPage> createState() => _CommerceOrdersPageState();
}

class _CommerceOrdersPageState extends State<CommerceOrdersPage> {
  late final CommerceOrderService _orderService;
  late Future<List<CommerceOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? CommerceOrderService();
    if (widget.initialOrders != null) {
      _ordersFuture = Future.value(widget.initialOrders);
    } else {
      _ordersFuture = _orderService.fetchOrders();
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      if (widget.initialOrders != null) {
        _ordersFuture = Future.value(widget.initialOrders);
      } else {
        _ordersFuture = _orderService.fetchOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes de Comercio')),
      body: FutureBuilder<List<CommerceOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay órdenes'));
          }
          final orders = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Orden #${order.id}'),
                    subtitle: Text('Estado: ${order.status}'),
                    trailing: Text('${order.total.toStringAsFixed(2)}\$', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommerceOrderDetailPage(orderId: order.id),
                        ),
                      ).then((value) => _refresh());
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 