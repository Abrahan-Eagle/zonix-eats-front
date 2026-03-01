import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/config/app_config.dart';
import 'dart:async'; // Added for StreamSubscription
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _pusherSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _initializePusher();
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await _orderService.getUserOrders();
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initializePusher() async {
    if (!AppConfig.enablePusher) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId <= 0) return;

      _pusherSubscription?.cancel();
      await PusherService.instance.subscribeToUserChannel(
        userId,
        onEvent: (eventName, data) {
          final mapped = <String, dynamic>{
            'type': _mapPusherEventToType(eventName),
            'data': data,
          };
          _handlePusherMessage(mapped);
        },
      );
    } catch (e) {
      debugPrint('Error inicializando Pusher: $e');
    }
  }

  String _mapPusherEventToType(String eventName) {
    switch (eventName) {
      case 'OrderStatusChanged':
        return 'order_status_changed';
      case 'OrderCreated':
        return 'order_created';
      case 'PaymentValidated':
        return 'payment_validated';
      default:
        return eventName;
    }
  }

  void _handlePusherMessage(Map<String, dynamic> message) {
    final type = message['type'];
    
    switch (type) {
      case 'order_status_changed':
      case 'order_created':
      case 'payment_validated':
        // Recargar órdenes cuando hay cambios
        _loadOrders();
        break;
      case 'delivery_location_updated':
        // Actualizar ubicación del delivery si está en la página de tracking
        _updateDeliveryLocation(message);
        break;
    }
  }

  void _updateDeliveryLocation(Map<String, dynamic> message) {
    final orderId = message['order_id'];
    final latitude = message['latitude'];
    final longitude = message['longitude'];

    // Aquí podrías actualizar el estado de tracking si estás en esa página
    debugPrint('Ubicación actualizada para orden $orderId: $latitude, $longitude');
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
            title: const Text('Órdenes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: const IconThemeData(color: AppColors.white),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar pedidos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes pedidos aún',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando hagas tu primer pedido, aparecerá aquí',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navegar a la página de restaurantes
                Navigator.pushNamed(context, '/restaurants');
              },
              child: const Text('Explorar Restaurantes'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            color: AppColors.cardBg(context),
            shadowColor: AppColors.purple.withValues(alpha: 0.10),
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: Icon(Icons.receipt_long, color: AppColors.accentButton(context)),
              title: Text('Orden #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText(context))),
              subtitle: Text('Estado: ${order.status}', style: TextStyle(color: AppColors.secondaryText(context))),
              trailing: Text('\$${order.total.toStringAsFixed(2)}', style: TextStyle(color: AppColors.success(context), fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailPage(
                      orderId: order.id,
                      order: order,
                    ),
                  ),
                ).then((_) => _loadOrders());
              },
            ),
          );
        },
      ),
    );
  }

}
