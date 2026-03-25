import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/services/delivery_company_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class DeliveryCompanyOrdersPage extends StatefulWidget {
  const DeliveryCompanyOrdersPage({super.key, this.highlightOrderId});

  /// Si viene de una notificación, enfoca la pestaña de órdenes en curso.
  final int? highlightOrderId;

  @override
  State<DeliveryCompanyOrdersPage> createState() => _DeliveryCompanyOrdersPageState();
}

class _DeliveryCompanyOrdersPageState extends State<DeliveryCompanyOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _pusherSub;
  String? _companyChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final service = context.read<DeliveryCompanyService>();
    await service.loadDashboard();
    if (!mounted) return;
    _loadAll();
    await _subscribePusher();
    if (!mounted) return;
    if (widget.highlightOrderId != null) {
      _tabController.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notificación: orden #${widget.highlightOrderId}')),
      );
    }
  }

  @override
  void dispose() {
    _unsubscribePusher();
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    if (!mounted) return;
    final service = context.read<DeliveryCompanyService>();
    service.loadOrders();
    service.loadPendingOrders();
    service.loadPendingPaymentOrders();
  }

  Future<void> _subscribePusher() async {
    if (!AppConfig.enablePusher || !mounted) return;

    final service = context.read<DeliveryCompanyService>();
    final dashboard = service.dashboardData;
    final companyId = (dashboard['company'] as Map?)?['id'];
    if (companyId != null) {
      _companyChannel = 'private-company.$companyId';
      await PusherService.instance.subscribeToChannel(_companyChannel!);
    }

    _pusherSub?.cancel();
    _pusherSub = PusherService.instance.eventStream.listen((event) {
      final eventName = event['eventName']?.toString() ?? '';
      final channelName = event['channelName']?.toString() ?? '';

      final isRelevant = channelName == _companyChannel ||
          (eventName.contains('NotificationCreated') || eventName.contains('PaymentValidated'));

      if (isRelevant &&
          (eventName.contains('OrderStatusChanged') ||
           eventName.contains('NotificationCreated') ||
           eventName.contains('PaymentValidated') ||
           eventName.contains('OrderPendingAssignment')) && mounted) {
        _loadAll();
      }
    });
  }

  void _unsubscribePusher() {
    _pusherSub?.cancel();
    _pusherSub = null;
    if (_companyChannel != null) {
      PusherService.instance.unsubscribeFromChannel(_companyChannel!);
      _companyChannel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pagos'),
            Tab(text: 'Asignar'),
            Tab(text: 'En curso'),
            Tab(text: 'Completadas'),
          ],
        ),
      ),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, service, _) {
          if (service.ordersLoading && service.orders.isEmpty && service.pendingOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final active = service.orders.where((o) {
            final s = o['status'] as String? ?? '';
            return !['delivered', 'cancelled'].contains(s);
          }).toList();

          final completed = service.orders.where((o) {
            final s = o['status'] as String? ?? '';
            return ['delivered', 'cancelled'].contains(s);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPendingPaymentTab(service),
              _buildPendingTab(service),
              _buildOrderList(active, 'No hay órdenes en curso'),
              _buildOrderList(completed, 'No hay órdenes completadas'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingPaymentTab(DeliveryCompanyService service) {
    if (service.pendingPaymentOrdersLoading && service.pendingPaymentOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (service.pendingPaymentOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 64, color: AppColors.secondaryText(context)),
            const SizedBox(height: 16),
            Text('No hay pagos de envío pendientes de validar', style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context)), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => service.loadPendingPaymentOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: service.pendingPaymentOrders.length,
        itemBuilder: (context, i) {
          final order = service.pendingPaymentOrders[i];
          return _buildPaymentOrderCard(order, service);
        },
      ),
    );
  }

  Widget _buildPaymentOrderCard(Map<String, dynamic> order, DeliveryCompanyService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderNumber = order['order_number'] ?? '#${order['id']}';
    final deliveryFee = _num(order['delivery_fee']);
    final orderId = order['id'] as int? ?? 0;
    final payments = order['order_payments'] as List<dynamic>? ?? [];
    final deliveryPayment = payments.firstWhere((p) => p['type'] == 'delivery', orElse: () => null);
    final reference = deliveryPayment?['reference_number'] ?? '';
    final method = deliveryPayment?['payment_method_label'] ?? '';
    final proofPath = deliveryPayment?['payment_proof']?.toString();
    final proofUrl = _paymentProofImageUrl(proofPath);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Orden $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Pago pendiente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (method.isNotEmpty) _infoRow(Icons.payment, 'Método: $method'),
          if (reference.isNotEmpty) _infoRow(Icons.numbers, 'Referencia: $reference'),
          _infoRow(Icons.attach_money, 'Envío: \$${deliveryFee.toStringAsFixed(2)}'),
          if (proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Comprobante de envío',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 6),
            _buildDeliveryPaymentProof(context, proofUrl),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await service.validateDeliveryPayment(orderId, true);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pago validado' : 'Error al validar')));
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Validar'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await service.validateDeliveryPayment(orderId, false, rejectionReason: 'Pago de envío rechazado');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pago rechazado' : 'Error al rechazar')));
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(DeliveryCompanyService service) {
    if (service.pendingOrdersLoading && service.pendingOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (service.pendingOrdersError != null && service.pendingOrders.isEmpty) {
      return _buildError(service.pendingOrdersError!, () {
        service.loadPendingOrders();
      });
    }
    if (service.pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late, size: 64, color: AppColors.secondaryText(context)),
            const SizedBox(height: 16),
            Text(
              'No hay órdenes pendientes de asignación',
              style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => service.loadPendingOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: service.pendingOrders.length,
        itemBuilder: (context, i) {
          final order = service.pendingOrders[i];
          return _buildPendingOrderCard(order, service);
        },
      ),
    );
  }

  Widget _buildPendingOrderCard(Map<String, dynamic> order, DeliveryCompanyService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderNumber = order['order_number'] ?? '#${order['id']}';
    final total = _num(order['total']);
    final deliveryFee = _num(order['delivery_fee']);
    final createdAt = order['created_at'] as String?;
    final commerce = order['commerce'] as Map<String, dynamic>? ?? {};
    final commerceName = commerce['business_name'] ?? commerce['name'] ?? 'Comercio';
    String dateStr = '';
    if (createdAt != null) {
      try {
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt));
      } catch (_) {
        dateStr = createdAt;
      }
    }
    final orderId = order['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: () => _openAssignOrderPage(context, orderId, orderNumber, service),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Orden $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Sin asignar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.store, commerceName),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.schedule, dateStr),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Delivery: \$${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.green)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Toca para asignar repartidor', style: TextStyle(fontSize: 12, color: AppColors.orange)),
          ],
        ),
      ),
    );
  }

  void _openAssignOrderPage(BuildContext context, int orderId, String orderNumber, DeliveryCompanyService service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _AssignOrderPage(orderId: orderId, orderNumber: orderNumber, service: service),
      ),
    ).then((_) {
      if (context.mounted) {
        service.loadPendingOrders();
        service.loadOrders();
      }
    });
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String emptyMsg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.secondaryText(context)),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<DeliveryCompanyService>().loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, i) => _buildOrderCard(orders[i], isDark),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    final orderNumber = order['order_number'] ?? '#${order['id']}';
    final status = order['status'] as String? ?? '';
    final total = _num(order['total']);
    final deliveryFee = _num(order['delivery_fee']);
    final createdAt = order['created_at'] as String?;

    final commerce = order['commerce'] as Map<String, dynamic>? ?? {};
    final commerceName = commerce['business_name'] ?? commerce['name'] ?? 'Comercio';

    final orderDelivery = order['order_delivery'] as Map<String, dynamic>?;
    final agentData = orderDelivery?['agent'] as Map<String, dynamic>?;
    final agentProfile = agentData?['profile'] as Map<String, dynamic>?;
    final agentName = agentProfile != null
        ? '${agentProfile['firstName'] ?? ''} ${agentProfile['lastName'] ?? ''}'.trim()
        : 'Sin asignar';

    String dateStr = '';
    if (createdAt != null) {
      try {
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt));
      } catch (_) {
        dateStr = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.white12 : AppColors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Orden $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.store, commerceName),
          const SizedBox(height: 4),
          _infoRow(Icons.delivery_dining, agentName),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            _infoRow(Icons.schedule, dateStr),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Delivery: \$${deliveryFee.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.secondaryText(context)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)))),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending_payment':
        color = AppColors.orange;
        label = 'Pago pendiente';
        break;
      case 'paid':
        color = AppColors.blue;
        label = 'Pagada';
        break;
      case 'processing':
        color = AppColors.blue;
        label = 'Procesando';
        break;
      case 'shipped':
        color = AppColors.purple;
        label = 'Enviada';
        break;
      case 'delivered':
        color = AppColors.green;
        label = 'Entregada';
        break;
      case 'cancelled':
        color = AppColors.red;
        label = 'Cancelada';
        break;
      default:
        color = AppColors.gray;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Misma lógica que `commerce_order_detail_page`: URL absoluta al archivo en storage.
  String _paymentProofImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base$path' : '$base/storage/$path';
  }

  Widget _buildDeliveryPaymentProof(BuildContext context, String proofUrl) {
    final isPdf = proofUrl.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      return const Row(
        children: [
          Icon(Icons.picture_as_pdf, size: 40, color: AppColors.red),
          SizedBox(width: 10),
          Expanded(child: Text('Comprobante adjunto (PDF)')),
        ],
      );
    }
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(
                proofUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          proofUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Row(
            children: [
              Icon(Icons.receipt_long, size: 40, color: AppColors.secondaryText(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla para elegir un agente y asignar la orden.
class _AssignOrderPage extends StatefulWidget {
  const _AssignOrderPage({
    required this.orderId,
    required this.orderNumber,
    required this.service,
  });

  final int orderId;
  final String orderNumber;
  final DeliveryCompanyService service;

  @override
  State<_AssignOrderPage> createState() => _AssignOrderPageState();
}

class _AssignOrderPageState extends State<_AssignOrderPage> {
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.loadAvailableAgentsForOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Asignar orden ${widget.orderNumber}'),
      ),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, service, _) {
          if (service.availableAgentsLoading && service.availableAgentsForOrder.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (service.availableAgentsError != null && service.availableAgentsForOrder.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(service.availableAgentsError ?? 'Error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => service.loadAvailableAgentsForOrder(widget.orderId),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (service.availableAgentsForOrder.isEmpty) {
            return Center(
              child: Text(
                'No hay agentes disponibles (activos y sin orden en curso)',
                style: TextStyle(color: AppColors.secondaryText(context)),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.availableAgentsForOrder.length,
            itemBuilder: (context, i) {
              final agent = service.availableAgentsForOrder[i];
              final name = agent['name'] as String? ?? 'Sin nombre';
              final distanceKm = (agent['distance_km'] as num?)?.toDouble() ?? 0;
              final vehicleType = agent['vehicle_type'] as String? ?? '';
              final rating = (agent['rating'] as num?)?.toDouble() ?? 0;
              final agentId = agent['id'] as int? ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grayDark : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.white12 : AppColors.black12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: AppColors.green)),
                          if (vehicleType.isNotEmpty)
                            Text(vehicleType, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: AppColors.orange),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _assigning
                          ? null
                          : () async {
                              setState(() => _assigning = true);
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await widget.service.assignOrderToAgent(widget.orderId, agentId);
                              if (!mounted) return;
                              setState(() => _assigning = false);
                              if (!mounted) return;
                              if (ok) {
                                navigator.pop(true);
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('No se pudo asignar. Intenta de nuevo.')),
                                );
                              }
                            },
                      icon: _assigning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add),
                      label: Text(_assigning ? 'Asignando...' : 'Asignar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
