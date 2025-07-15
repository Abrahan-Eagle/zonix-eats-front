import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/websocket_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'dart:async'; // Added for StreamSubscription
import 'package:zonix/features/utils/app_colors.dart';

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
  WebSocketService? _webSocketService;
  StreamSubscription? _webSocketSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

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

  Future<void> _initializeWebSocket() async {
    if (!AppConfig.enableWebsockets) return;

    try {
      _webSocketService = WebSocketService();
      await _webSocketService!.connect();
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null) {
        // Suscribirse a actualizaciones de órdenes del usuario
        await _webSocketService!.subscribeToChannel('orders.user.${user['id']}');
        
        _webSocketSubscription = _webSocketService!.messageStream?.listen((message) {
          _handleWebSocketMessage(message);
        });
      }
    } catch (e) {
      print('Error inicializando WebSocket: $e');
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
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
    final estimatedArrival = message['estimated_arrival'];
    
    // Aquí podrías actualizar el estado de tracking si estás en esa página
    print('Ubicación actualizada para orden $orderId: $latitude, $longitude');
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
            iconTheme: IconThemeData(color: AppColors.white),
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
            shadowColor: AppColors.purple.withOpacity(0.10),
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: Icon(Icons.receipt_long, color: AppColors.accentButton(context)),
              title: Text('Orden #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText(context))),
              subtitle: Text('Estado: ${order.status}', style: TextStyle(color: AppColors.secondaryText(context))),
              trailing: Text('${order.total}₡', style: TextStyle(color: AppColors.success(context), fontWeight: FontWeight.bold)),
              onTap: () {
                // Acción para ver detalles de la orden
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navegar a detalles de la orden
          Navigator.pushNamed(
            context,
            '/order-details',
            arguments: order,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.commerce?['name'] ?? 'Restaurante',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${order.items.length} productos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'pendiente_pago':
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case 'pagado':
        color = Colors.blue;
        text = 'Pagado';
        break;
      case 'en_preparacion':
        color = Colors.purple;
        text = 'Preparando';
        break;
      case 'listo_retirar':
        color = Colors.green;
        text = 'Listo';
        break;
      case 'en_camino':
        color = Colors.indigo;
        text = 'En Camino';
        break;
      case 'entregado':
        color = Colors.green;
        text = 'Entregado';
        break;
      case 'cancelado':
        color = Colors.red;
        text = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }
}
