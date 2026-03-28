import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zonix/models/commerce_order.dart';
import 'package:zonix/features/services/commerce_order_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';
import '../../utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';

class CommerceOrderDetailPage extends StatefulWidget {
  const CommerceOrderDetailPage({
    super.key,
    required this.orderId,
    this.order,
  });

  final int orderId;
  final CommerceOrder? order;

  @override
  State<CommerceOrderDetailPage> createState() => _CommerceOrderDetailPageState();
}

class _CommerceOrderDetailPageState extends State<CommerceOrderDetailPage> {
  CommerceOrder? _order;
  bool _loading = true;
  String? _error;
  bool _updating = false;
  bool _pusherSubscribed = false;
  StreamSubscription<Map<String, dynamic>>? _pusherSubscription;
  String? _pickupQrPayload;
  Future<void>? _loadOrderInFlight;

  static num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      _loadOrder();
    } else {
      _loading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToOrderUpdates());
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    if (_pusherSubscribed) {
      PusherService.instance.unsubscribeFromChannel('private-orders.${widget.orderId}');
    }
    super.dispose();
  }

  Future<void> _subscribeToOrderUpdates() async {
    if (!AppConfig.enablePusher || _pusherSubscribed || !mounted) return;
    final ok = await PusherService.instance.subscribeToOrderChat(widget.orderId);
    
    if (ok && mounted) {
      _pusherSubscription?.cancel();
      _pusherSubscription = PusherService.instance.eventStream.listen((event) {
        final eventName = event['eventName']?.toString() ?? '';
        final channelName = event['channelName']?.toString() ?? '';

        if (channelName == 'private-orders.${widget.orderId}') {
          if ((eventName.contains('OrderStatusChanged') || 
               eventName.contains('PaymentValidated')) && mounted) {
            _loadOrder();
          }
        }
      });
      _pusherSubscribed = true;
    }
  }

  Future<void> _loadOrder() async {
    if (_loadOrderInFlight != null) return _loadOrderInFlight!;
    _loadOrderInFlight = _loadOrderImpl();
    try {
      await _loadOrderInFlight!;
    } finally {
      _loadOrderInFlight = null;
    }
  }

  Future<void> _loadOrderImpl() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await CommerceOrderService.getOrder(widget.orderId);
      String? qr;
      if (order.status == 'processing' && order.isDelivery) {
        qr = await CommerceOrderService.getPickupQrPayload(widget.orderId);
      }
      if (mounted) {
        setState(() {
          _order = order;
          _pickupQrPayload = qr;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      await CommerceOrderService.updateOrderStatus(widget.orderId, status);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a $status'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _rejectOrder() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectOrderDialog(),
    );
    if (reason == null || !mounted) return;

    setState(() => _updating = true);
    try {
      await CommerceOrderService.rejectOrder(
        widget.orderId,
        reason: reason.isEmpty ? null : reason,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden rechazada'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _validatePayment(bool isValid) async {
    setState(() => _updating = true);
    try {
      final response = await CommerceOrderService.validatePayment(widget.orderId, isValid);
      await _loadOrder();
      if (!mounted) return;

      if (isValid) {
        final allValidated = response['all_payments_validated'] == true;
        final msg = response['message'] as String? ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(allValidated ? 'Pago validado' : msg),
            backgroundColor: AppColors.green,
          ),
        );
        if (allValidated) {
          await _updateStatus('processing');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago rechazado'), backgroundColor: AppColors.red),
        );
        if (_order?.isCancelled == true) {
          Navigator.pop(context);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
        await _loadOrder();
        if (mounted && _order?.isCancelled == true) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  static String _paymentMethodLabel(String? type) {
    if (type == null || type.isEmpty) return '—';
    switch (type) {
      case 'mobile_payment':
        return 'Pago móvil';
      case 'bank_transfer':
        return 'Transferencia';
      case 'card':
      case 'stripe':
        return 'Tarjeta';
      case 'cash':
        return 'Efectivo';
      case 'paypal':
        return 'PayPal';
      case 'mercadopago':
        return 'Mercado Pago';
      case 'digital_wallet':
        return 'Billetera digital';
      default:
        return type.replaceAll('_', ' ').split(' ').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
    }
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    // Backend guarda en disco public (storage); alineamos con detalle de buyer.
    return path.startsWith('/') ? '$base$path' : '$base/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de orden')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Orden no encontrada', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${order.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat con el cliente',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommerceChatMessagesPage(
                    orderId: order.id,
                    customerName: order.customerName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadOrder,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(order.customerName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('Tel: ${order.customerPhone}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Productos',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...order.items.map((item) {
                      final qty = _parseNum(item['quantity'] ?? 1);
                      final price = _parseNum(item['unit_price'] ?? item['price'] ?? 0);
                      final name = item['product']?['name'] ?? 'Producto';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('${qty.toInt()} x \$${price.toStringAsFixed(2)}'),
                          trailing: Text(
                            '\$${(qty * price).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                    if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Personalización del pedido',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt_outlined,
                                  size: 20, color: AppColors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  order.notes!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _TotalRow('Subtotal',
                                '\$${order.total.toStringAsFixed(2)}'),
                            _TotalRow('Estado', order.statusText),
                            _TotalRow('Tipo', order.deliveryTypeText),
                            if (order.estimatedDeliveryMinutes != null &&
                                order.estimatedDeliveryMinutes! > 0)
                              _TotalRow(
                                'Tiempo estimado de entrega',
                                '~${order.estimatedDeliveryMinutes} min',
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (order.isPendingPayment && !order.approvedForPayment) ...[
                      const SizedBox(height: 16),
                      Text('Acciones',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _updating
                                ? null
                                : () async {
                                    setState(() => _updating = true);
                                    try {
                                      await CommerceOrderService
                                          .approveForPayment(widget.orderId);
                                      await _loadOrder();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Orden aprobada para pago'),
                                          backgroundColor: AppColors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                                            ),
                                            backgroundColor: AppColors.red,
                                          ),
                                        );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _updating = false);
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Aprobar para pago'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _rejectOrder(),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Rechazar orden'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              side: const BorderSide(color: AppColors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order.hasPaymentProof && !order.isPaymentValidated) ...[
                      const SizedBox(height: 16),
                      Text('Comprobante de pago',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Datos para conciliar (método, referencia, monto)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.amber.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Datos para conciliar',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _TotalRow('Método de pago', _paymentMethodLabel(order.paymentMethod)),
                                    _TotalRow('Referencia / Nº operación', order.referenceNumber?.isNotEmpty == true ? order.referenceNumber! : '—'),
                                    _TotalRow('Monto de la orden', '\$${order.total.toStringAsFixed(2)}'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Datos del comprador',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    _TotalRow('Nombre', order.customerName),
                                    _TotalRow('Email', order.customerEmail),
                                    _TotalRow('Teléfono', order.customerPhone),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (order.paymentProof != null &&
                                  order.paymentProof!.isNotEmpty)
                                Builder(
                                  builder: (ctx) {
                                    final proofUrl = _imageUrl(order.paymentProof);
                                    final isPdf = proofUrl.toLowerCase().endsWith('.pdf');
                                    if (isPdf) {
                                      return const Row(
                                        children: [
                                          Icon(Icons.picture_as_pdf, size: 48, color: AppColors.red),
                                          SizedBox(width: 12),
                                          Text('Comprobante (PDF)'),
                                        ],
                                      );
                                    }
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog<void>(
                                          context: ctx,
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
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.receipt,
                                            size: 64,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (order.isPendingPayment) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _updating ? null : () => _validatePayment(true),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Validar pago'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _updating
                                        ? null
                                        : () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Rechazar pago'),
                                                content: const Text(
                                                    '¿Estás seguro de que quieres rechazar este comprobante de pago?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: TextButton.styleFrom(foregroundColor: AppColors.red),
                                                    child: const Text('Sí, rechazar'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) _validatePayment(false);
                                          },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Rechazar pago'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.red,
                                      side: const BorderSide(color: AppColors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (order.isPaid) ...[
                      const SizedBox(height: 16),
                      Text('Pago recibido',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (order.paymentMethod != null || order.referenceNumber != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _TotalRow('Método', _paymentMethodLabel(order.paymentMethod)),
                                if (order.referenceNumber != null && order.referenceNumber!.isNotEmpty)
                                  _TotalRow('Referencia', order.referenceNumber!),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _updating ? null : () => _updateStatus('processing'),
                            icon: const Icon(Icons.restaurant),
                            label: const Text('Comenzar a preparar'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                          ),
                          ElevatedButton.icon(
                            onPressed: _updating ? null : () => _updateStatus('cancelled'),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancelar'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                          ),
                        ],
                      ),
                    ],
                    if (order.status == 'processing') ...[
                      const SizedBox(height: 16),
                      if (order.isPickup) ...[
                        const Icon(Icons.restaurant, size: 48, color: AppColors.orange),
                        const SizedBox(height: 8),
                        Text(
                          'Preparando pedido',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cuando el pedido esté listo, notifica al cliente para que pase a recogerlo.',
                          style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _updating ? null : () => _updateStatus('shipped'),
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Pedido listo para recoger'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (order.isDelivery) ...[
                        if (_pickupQrPayload != null) ...[
                          Text(
                            'Muestra este QR al repartidor',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(
                                data: _pickupQrPayload!,
                                version: QrVersions.auto,
                                size: 200,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_pickupQrPayload == null)
                          Text(
                            'El repartidor escaneará el QR para recoger el pedido',
                            style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
                            textAlign: TextAlign.center,
                          ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _updating ? null : () => _updateStatus('cancelled'),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar orden'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                      ),
                    ],
                    if (order.status == 'shipped' && order.isPickup) ...[
                      const SizedBox(height: 16),
                      const Icon(Icons.storefront, size: 48, color: AppColors.green),
                      const SizedBox(height: 8),
                      Text(
                        'Esperando al cliente',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El cliente fue notificado. Cuando llegue y recoja su pedido, confirma la entrega.',
                        style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _updating ? null : () => _updateStatus('delivered'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Entregar al cliente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_updating)
            Positioned.fill(
              child: Container(
                color: AppColors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}

class _RejectOrderDialog extends StatefulWidget {
  const _RejectOrderDialog();

  @override
  State<_RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<_RejectOrderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechazar orden'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Estás seguro? Esta orden se cancelará. '
            'Usa el chat para acordar con el cliente antes de rechazar.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Ej: Falta de ingredientes, no hay acuerdo',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: const Text('Rechazar orden'),
        ),
      ],
    );
  }
}
