import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/order.dart';

class CommerceOrdersPage extends StatefulWidget {
  const CommerceOrdersPage({Key? key}) : super(key: key);

  @override
  State<CommerceOrdersPage> createState() => _CommerceOrdersPageState();
}

class _CommerceOrdersPageState extends State<CommerceOrdersPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final orderService = Provider.of<OrderService>(context, listen: false);
    _ordersFuture = orderService.fetchOrders(); // Asume que fetchOrders trae las órdenes del comercio
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes del Comercio')),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
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
                        final orderService = Provider.of<OrderService>(context, listen: false);
                        _ordersFuture = orderService.fetchOrders();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
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
                  title: Text('Orden #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado: ${order.status}'),
                      if (order.paymentStatus == 'pending')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Comprobante: Pendiente'),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await Provider.of<OrderService>(context, listen: false).validarComprobante(order.id, 'validar');
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante validado')));
                                      setState(() {
                                        final orderService = Provider.of<OrderService>(context, listen: false);
                                        _ordersFuture = orderService.fetchOrders();
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al validar comprobante')));
                                    }
                                  },
                                  child: const Text('Validar'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await Provider.of<OrderService>(context, listen: false).validarComprobante(order.id, 'rechazar');
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante rechazado')));
                                      setState(() {
                                        final orderService = Provider.of<OrderService>(context, listen: false);
                                        _ordersFuture = orderService.fetchOrders();
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al rechazar comprobante')));
                                    }
                                  },
                                  child: const Text('Rechazar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                  trailing: Text('Total: ${order.total ?? '-'}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 