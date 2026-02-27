import 'package:flutter/material.dart';
import 'package:zonix/models/commerce_order.dart';
import 'package:zonix/features/services/commerce_order_service.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';

class CommerceOrderDetailPage extends StatefulWidget {
  const CommerceOrderDetailPage({
    Key? key,
    required this.orderId,
    this.order,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      _loadOrder();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await CommerceOrderService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
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
      await CommerceOrderService.validatePayment(widget.orderId, isValid);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isValid ? 'Pago validado' : 'Pago rechazado'),
            backgroundColor: isValid ? AppColors.green : AppColors.red,
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

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base$path' : '$base/$path';
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
              Icon(Icons.error_outline, size: 64, color: AppColors.red),
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
      body: _updating
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                      final qty = item['quantity'] ?? 1;
                      final price = (item['unit_price'] ?? item['price'] ?? 0)
                          as num;
                      final name = item['product']?['name'] ?? 'Producto';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('$qty x \$${price.toStringAsFixed(2)}'),
                          trailing: Text(
                            '\$${(qty * price).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
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
                          ],
                        ),
                      ),
                    ),
                    if (order.status == 'pending_payment') ...[
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
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Orden aprobada para pago'),
                                            backgroundColor: AppColors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                                            ),
                                            backgroundColor: AppColors.red,
                                          ),
                                        );
                                      }
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
                            children: [
                              if (order.paymentProof != null &&
                                  order.paymentProof!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imageUrl(order.paymentProof),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.receipt,
                                      size: 64,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _validatePayment(true),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Validar'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.green),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _validatePayment(false),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Rechazar'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (order.isPaid) ...[
                      const SizedBox(height: 16),
                      Text('Cambiar estado',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _updateStatus('processing'),
                            child: const Text('En preparación'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _updateStatus('cancelled'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                    if (order.status == 'processing') ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _updateStatus('shipped'),
                            child: const Text('Enviar'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _updateStatus('cancelled'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red),
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
          child: const Text('Rechazar orden'),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
        ),
      ],
    );
  }
}
