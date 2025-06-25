import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final orderService = Provider.of<OrderService>(context, listen: false);
    _ordersFuture = orderService.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes')),
      body: FutureBuilder<List<dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay órdenes'));
          }
          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Orden #${order['id'] ?? '-'}'),
                  subtitle: Text('Estado: ${order['status'] ?? 'Desconocido'}'),
                  trailing: Text('Total: ${order['total'] ?? '-'}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
