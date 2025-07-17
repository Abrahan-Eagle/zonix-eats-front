import 'package:flutter/material.dart';
import '../../../models/commerce_order.dart';
import '../../../features/services/commerce_order_service.dart';

class CommerceOrderDetailPage extends StatefulWidget {
  final CommerceOrder order;
  const CommerceOrderDetailPage({Key? key, required this.order}) : super(key: key);

  @override
  State<CommerceOrderDetailPage> createState() => _CommerceOrderDetailPageState();
}

class _CommerceOrderDetailPageState extends State<CommerceOrderDetailPage> {
  bool _loading = false;
  String? _error;
  late CommerceOrder _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      final updatedOrder = await CommerceOrderService.updateOrderStatus(_order.id, newStatus);
      if (!mounted) return;
      setState(() { _order = updatedOrder; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _validatePayment(bool isValid, {String? reason}) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceOrderService.validatePayment(_order.id, isValid, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? 'Pago validado' : 'Pago rechazado'),
          backgroundColor: isValid ? Colors.green : Colors.orange,
        ),
      );
      // Recargar la orden
      final updatedOrder = await CommerceOrderService.getOrder(_order.id);
      if (mounted) setState(() { _order = updatedOrder; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al validar pago: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment': return 'Pendiente de Pago';
      case 'paid': return 'Pagado';
      case 'preparing': return 'En Preparación';
      case 'ready': return 'Listo';
      case 'on_way': return 'En Camino';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment': return Colors.orange;
      case 'paid': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'on_way': return Colors.indigo;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden #${_order.id}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _order.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _order.isDelivery ? Icons.local_shipping : Icons.store,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _order.deliveryTypeText,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '\$${_order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Creada: ${_formatDateTime(_order.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Nombre', _order.customerName, Icons.person),
            _buildInfoRow('Email', _order.customerEmail, Icons.email),
            _buildInfoRow('Teléfono', _order.customerPhone, Icons.phone),
            if (_order.isDelivery && _order.deliveryAddress != null)
              _buildInfoRow('Dirección', _order.deliveryAddress!, Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_order.itemCount} items',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._order.items.map((item) => _buildOrderItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final quantity = item['quantity'] ?? 0;
    final unitPrice = (item['unit_price'] is String)
        ? double.tryParse(item['unit_price']) ?? 0.0
        : (item['unit_price'] ?? 0.0).toDouble();
    final total = quantity * unitPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Producto desconocido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (product['description'] != null)
                  Text(
                    product['description'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    if (!_order.hasPaymentProof) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_order.paymentMethod != null)
              _buildInfoRow('Método', _order.paymentMethod!, Icons.payment),
            if (_order.referenceNumber != null)
              _buildInfoRow('Referencia', _order.referenceNumber!, Icons.receipt),
            if (_order.paymentValidatedAt != null)
              _buildInfoRow('Validado', _formatDateTime(_order.paymentValidatedAt!), Icons.check_circle),
            const SizedBox(height: 12),
            if (_order.paymentProof != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _order.paymentProof!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            if (_order.isPendingPayment && _order.hasPaymentProof) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _validatePayment(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Validar Pago'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _validatePayment(false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Rechazar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions() {
    if (_order.isCancelled || _order.isDelivered) return const SizedBox.shrink();

    final nextStatuses = _getNextStatuses(_order.status);
    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nextStatuses.map((status) => ElevatedButton(
                onPressed: _loading ? null : () => _updateStatus(status),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(status),
                ),
                child: Text(_getStatusText(status)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getNextStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'pending_payment':
        return ['paid'];
      case 'paid':
        return ['preparing', 'cancelled'];
      case 'preparing':
        return ['ready', 'cancelled'];
      case 'ready':
        return ['on_way', 'cancelled'];
      case 'on_way':
        return ['delivered'];
      default:
        return [];
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${_order.id}'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              _buildHeader(),
              _buildCustomerInfo(),
              _buildOrderItems(),
              _buildPaymentInfo(),
              _buildStatusActions(),
              const SizedBox(height: 100), // Espacio para el botón flotante
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: _order.isReady && _order.isDelivery
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : () async {
                try {
                  await CommerceOrderService.requestDelivery(_order.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud de delivery enviada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al solicitar delivery: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.local_shipping),
              label: const Text('Solicitar Delivery'),
            )
          : null,
    );
  }
} 