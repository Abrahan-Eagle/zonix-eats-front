import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/utils/app_colors.dart';

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
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
                AppColors.headerGradientEnd(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Órdenes Comercio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: IconThemeData(color: AppColors.white),
          ),
        ),
      ),
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
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                color: AppColors.cardBg(context),
                shadowColor: AppColors.purple.withOpacity(0.10),
                elevation: 6,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  leading: Icon(Icons.store, color: AppColors.accentButton(context)),
                  title: Text('Orden #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText(context))),
                  subtitle: Text('Estado: ${order.status}', style: TextStyle(color: AppColors.secondaryText(context))),
                  trailing: Text('${order.total}\$', style: TextStyle(color: AppColors.success(context), fontWeight: FontWeight.bold)),
                  onTap: () {
                    // Acción para ver detalles de la orden de comercio
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 