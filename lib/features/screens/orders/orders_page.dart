import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/orders/order_history_detail_page.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/widgets/app_skeleton.dart';

/// Color primary del template (code1/code2 HTML): #3399ff
const Color _templatePrimary = AppColors.blue;

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
  int _tabIndex = 0; // 0 = Activas, 1 = Historial
  StreamSubscription? _pusherSubscription;

  @override
  void initState() {
    super.initState();
    _initOrders();
    _initializePusher();
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initOrders() async {
    final cached = await OrderService.getCachedOrders();
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() { _orders = cached; _isLoading = false; });
    }
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    if (!mounted) return;
    if (_orders.isEmpty) {
      setState(() { _isLoading = true; _error = null; });
    }
    try {
      final orders = await _orderService.getUserOrders();
      if (!mounted) return;
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      if (_orders.isEmpty) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final orders = await _orderService.getUserOrders();
      if (!mounted) return;
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _initializePusher() async {
    if (!AppConfig.enablePusher) return;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId <= 0) return;
      _pusherSubscription?.cancel();
      final ok = await PusherService.instance.subscribeToUserChannel(userId);
      if (ok && mounted) {
        _pusherSubscription = PusherService.instance.eventStream.listen((event) {
          final eventName = (event['canonicalEventName'] ?? event['eventName'])?.toString() ?? '';
          final channelName = event['channelName']?.toString() ?? '';
          final eventData = event['data'] is Map<String, dynamic>
              ? event['data'] as Map<String, dynamic>
              : <String, dynamic>{};

          if (channelName == 'private-user.$userId') {
            final mapped = <String, dynamic>{
              'type': _mapPusherEventToType(eventName),
              'data': eventData,
            };
            _handlePusherMessage(mapped);
          }
        });
      }
    } catch (e) {
      debugPrint('Error inicializando Pusher: $e');
    }
  }

  String _mapPusherEventToType(String eventName) {
    if (eventName.contains('OrderStatusChanged')) {
      return 'order_status_changed';
    }
    if (eventName.contains('OrderCreated')) {
      return 'order_created';
    }
    if (eventName.contains('PaymentValidated')) {
      return 'payment_validated';
    }
    if (eventName.contains('DeliveryLocationUpdated')) {
      return 'delivery_location_updated';
    }
    return eventName;
  }

  void _handlePusherMessage(Map<String, dynamic> message) {
    final type = message['type'];
    switch (type) {
      case 'order_status_changed':
      case 'order_created':
      case 'payment_validated':
        _loadOrders();
        _maybeShowOrderNotification(type, message['data'] as Map<String, dynamic>?);
        break;
      case 'delivery_location_updated':
        _updateDeliveryLocation(message);
        break;
    }
  }

  void _maybeShowOrderNotification(String type, Map<String, dynamic>? data) {
    if (!mounted || data == null) return;

    final notifService = context.read<NotificationService>();
    final orderId = data['order_id']?.toString() ?? '';

    switch (type) {
      case 'payment_validated':
        final isValidated = data['is_validated'] == true;
        final title = isValidated ? 'Pago validado' : 'Pago rechazado';
        final message = isValidated
            ? 'Tu pago de la orden #$orderId fue validado por el comercio.'
            : 'El pago de la orden #$orderId fue rechazado. Revisa los datos o sube un nuevo comprobante.';
        notifService.showInAppNotification(context, {
          'title': title,
          'message': message,
          'type': 'order',
          'data': {
            'order_id': orderId,
          },
        });
        break;
      case 'order_status_changed':
        final status = (data['status'] ?? '').toString();
        String statusText;
        switch (status) {
          case 'processing':
          case 'preparing':
            statusText = 'tu pedido está en preparación';
            break;
          case 'shipped':
          case 'out_for_delivery':
            statusText = 'tu pedido está en camino';
            break;
          case 'delivered':
            statusText = 'tu pedido fue entregado';
            break;
          case 'cancelled':
            statusText = 'tu pedido fue cancelado';
            break;
          default:
            statusText = 'el estado de tu pedido cambió';
        }
        notifService.showInAppNotification(context, {
          'title': 'Actualización de pedido',
          'message': 'Orden #$orderId: $statusText.',
          'type': 'order',
          'data': {
            'order_id': orderId,
          },
        });
        break;
      default:
        break;
    }
  }

  void _updateDeliveryLocation(Map<String, dynamic> message) {
    debugPrint('Ubicación actualizada para orden ${message['order_id']}');
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base$path' : '$base/storage/$path';
  }

  List<Order> get _activeOrders =>
      _orders.where((o) => !o.isDelivered && !o.isCancelled).toList();

  /// Activas más recientes primero (misma semántica que quiere ver el usuario en paralelo).
  List<Order> get _sortedActiveOrders {
    final list = List<Order>.from(_activeOrders);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Order> get _historyOrders =>
      _orders.where((o) => o.isDelivered || o.isCancelled).toList();

  String _commerceName(Order order) {
    final c = order.commerce;
    if (c == null) return 'Orden #${order.id}';
    return (c['name'] ?? c['business_name'] ?? 'Orden #${order.id}').toString();
  }

  String? _orderImageUrl(Order order) {
    if (order.items.isNotEmpty) {
      final img = order.items.first.productImage;
      if (img.isNotEmpty) return img.startsWith('http') ? img : _imageUrl(img);
    }
    final c = order.commerce;
    if (c != null && c['image'] != null && c['image'].toString().isNotEmpty) {
      final img = c['image'].toString();
      return img.startsWith('http') ? img : _imageUrl(img);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = AppColors.cardBg(context);
    final backgroundLight =
        isDark ? AppColors.backgroundDark : AppColors.grayLight;
    final primary = isDark ? AppColors.accentButton(context) : _templatePrimary;
    final borderColor =
        isDark ? AppColors.white.withValues(alpha: 0.08) : AppColors.grayLight;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabs(context, theme, surfaceColor, borderColor),
            Expanded(
              child: _isLoading
                  ? AppSkeleton.list(count: 5, useCards: true)
                  : _error != null
                      ? _buildError(theme)
                      : _orders.isEmpty
                          ? _buildEmpty(context, theme)
                          : RefreshIndicator(
                              onRefresh: () async {
                                await _loadOrders();
                              },
                              child: _tabIndex == 0
                                  ? _buildActivasContent(context, theme,
                                      surfaceColor, borderColor, primary)
                                  : _buildHistorialContent(context, theme,
                                      surfaceColor, borderColor, primary),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Añade todos los ítems de la orden al carrito (Pedir de nuevo).
  void _pedirDeNuevo(BuildContext context, Order order) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta orden no tiene ítems para agregar')),
      );
      return;
    }
    final cartService = Provider.of<CartService>(context, listen: false);
    for (final item in order.items) {
      cartService.addToCart(CartItem(
        id: item.productId,
        nombre: item.productName,
        precio: item.price,
        quantity: item.quantity,
        image: item.productImage.isNotEmpty ? item.productImage : null,
        imagen: item.productImage.isNotEmpty ? item.productImage : null,
        commerceId: order.commerceId,
      ));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${order.items.length} producto(s) agregados al carrito')),
      );
    }
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Widget _buildTabs(BuildContext context, ThemeData theme, Color surfaceColor,
      Color borderColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.grayDark.withValues(alpha: 0.5)
              : AppColors.grayLight.withValues(alpha: 0.8), // slate-200/80
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tabButton(
                label: 'Activas',
                selected: _tabIndex == 0,
                onTap: () => setState(() => _tabIndex = 0),
                theme: theme,
                surfaceColor: surfaceColor,
              ),
            ),
            Expanded(
              child: _tabButton(
                label: 'Historial',
                selected: _tabIndex == 1,
                onTap: () => setState(() => _tabIndex = 1),
                theme: theme,
                surfaceColor: surfaceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color surfaceColor,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? surfaceColor : AppColors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected
                  ? AppColors.primaryText(context)
                  : AppColors.secondaryText(context), // slate-900 / slate-500
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: AppColors.error(context)),
            const SizedBox(height: 16),
            Text('Error al cargar pedidos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!,
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Reintentar cargar pedidos',
              child: FilledButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: AppColors.secondaryText(context)),
            const SizedBox(height: 16),
            Text('No tienes pedidos aún',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context))),
            const SizedBox(height: 8),
            Text(
              'Cuando hagas tu primer pedido, aparecerá aquí',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppColors.secondaryText(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Explorar restaurantes',
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/restaurants'),
                icon: const Icon(Icons.storefront, size: 20),
                label: const Text('Explorar Restaurantes'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.accentButton(context)
                    : _templatePrimary,
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivasContent(
    BuildContext context,
    ThemeData theme,
    Color surfaceColor,
    Color borderColor,
    Color primary,
  ) {
    final activeList = _sortedActiveOrders;
    final historyForActivas = _historyOrders.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (activeList.isNotEmpty) ...[
          Text(
            activeList.length == 1 ? 'Pedido activo' : 'Pedidos activos',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : AppColors.primaryText(context)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < activeList.length; i++) ...[
            _buildCurrentOrderCard(
              context,
              activeList[i],
              theme,
              surfaceColor,
              borderColor,
              primary,
            ),
            if (i != activeList.length - 1) const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
        ],
        Text(
          'Historial Reciente',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.primaryText(context)),
        ),
        const SizedBox(height: 12),
        if (historyForActivas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aún no hay pedidos en el historial',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          )
        else
          ...historyForActivas.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryOrderCardCompact(
                    context, o, theme, surfaceColor, borderColor, primary),
              )),
      ],
    );
  }

  Widget _buildHistorialContent(
    BuildContext context,
    ThemeData theme,
    Color surfaceColor,
    Color borderColor,
    Color primary,
  ) {
    final history = _historyOrders;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Órdenes completadas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (history.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                'No hay órdenes completadas',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: history.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryOrderCardCompact(
                    context, history[i], theme, surfaceColor, borderColor, primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentOrderCard(
    BuildContext context,
    Order order,
    ThemeData theme,
    Color surfaceColor,
    Color borderColor,
    Color primary,
  ) {
    final imageUrl = _orderImageUrl(order);
    final name = _commerceName(order);
    final itemCount = order.items.fold<int>(0, (s, i) => s + i.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(80, 80),
                      )
                    : _placeholderImage(80, 80),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            order.statusText.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _progressForStatus(order.status),
                              backgroundColor: isDark
                                  ? AppColors.grayDark
                                  : AppColors.grayLight,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primary),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '15 min',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55)),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              Material(
                color: primary,
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
                shadowColor: primary.withValues(alpha: 0.3),
                child: InkWell(
                  onTap: () => _openOrderDetail(context, order),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Seguir Pedido',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            size: 18, color: AppColors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _progressForStatus(String status) {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return 0.2;
      case 'paid':
      case 'confirmed':
        return 0.35;
      case 'preparing':
      case 'processing':
        return 0.55;
      case 'ready':
      case 'shipped':
      case 'out_for_delivery':
        return 0.75;
      default:
        return 0.5;
    }
  }

  /// Card compacta para "Historial Reciente" (tab Activas): imagen 40px, "12 Oct • Entregado", Pedir de nuevo + Ver Recibo.
  Widget _buildHistoryOrderCardCompact(
    BuildContext context,
    Order order,
    ThemeData theme,
    Color surfaceColor,
    Color borderColor,
    Color primary,
  ) {
    final imageUrl = _orderImageUrl(order);
    final name = _commerceName(order);
    final dateStr = _formatOrderDate(order.createdAt);
    final statusText = order.isDelivered ? 'Entregado' : 'Cancelado';

    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openHistoryDetail(context, order),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(40, 40),
                      )
                    : _placeholderImage(40, 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr • $statusText',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: isDark ? AppColors.grayDark : AppColors.grayLight,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _pedirDeNuevo(context, order),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          'Pedir de nuevo',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openOrderDetail(context, order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Ver Recibo',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.bold)),
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

  String _formatOrderDate(DateTime d) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Widget _placeholderImage(double w, double h) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: w,
      height: h,
      color: dark ? AppColors.grayDark : AppColors.textMutedGray,
      child: Icon(Icons.store,
          color: dark ? AppColors.gray : AppColors.gray,
          size: w * 0.5),
    );
  }

  void _openOrderDetail(BuildContext context, Order order) {
    // Una sola pantalla de detalle: siempre OrderDetailPage (recibo + progreso/tracking según estado).
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(orderId: order.id, order: order),
      ),
    ).then((_) {
      if (mounted) _loadOrders();
    });
  }

  void _openHistoryDetail(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderHistoryDetailPage(order: order),
      ),
    );
  }
}
