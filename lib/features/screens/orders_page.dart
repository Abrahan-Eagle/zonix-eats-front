import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';
import '../../models/order.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _ordersFuture;

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
                      Text('Estado: ${order.estado ?? order.status ?? 'Desconocido'}'),
                      if (order.comprobanteUrl != null)
                        Text('Comprobante: Subido'),
                      if ((order.estado ?? '').contains('pendiente_pago') || (order.estado ?? '').contains('comprobante_subido'))
                        ElevatedButton(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
                            if (result != null && result.files.single.path != null) {
                              final file = result.files.single;
                              final fileType = file.extension == 'pdf' ? 'pdf' : (file.extension ?? 'jpg');
                              try {
                                await Provider.of<OrderService>(context, listen: false).uploadComprobante(order.id, file.path!, fileType);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comprobante subido correctamente')));
                                setState(() {
                                  final orderService = Provider.of<OrderService>(context, listen: false);
                                  _ordersFuture = orderService.fetchOrders();
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir comprobante')));
                              }
                            }
                          },
                          child: const Text('Subir comprobante de pago'),
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
