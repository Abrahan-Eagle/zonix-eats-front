import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/receipt_pdf_builder.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/widgets/osm_map_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.order,
  });

  final int orderId;
  final Order? order;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _updating = false;
  double? _deliveryLat;
  double? _deliveryLng;
  bool _trackingSubscribed = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      _loadOrder();
    } else {
      _loading = false;
      _subscribeToTracking();
    }
  }

  @override
  void didUpdateWidget(OrderDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order != widget.order) {
      _order = widget.order;
    }
  }

  @override
  void dispose() {
    if (_trackingSubscribed) {
      PusherService.instance.unsubscribeFromChannel('private-orders.${widget.orderId}');
    }
    super.dispose();
  }

  void _subscribeToTracking() {
    if (_order == null || _trackingSubscribed) return;
    final s = _order!.status;
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'processing' || s == 'paid') {
      PusherService.instance.subscribeToOrderChat(
        widget.orderId,
        onNewMessage: (eventName, data) {
          if (eventName.contains('DeliveryLocationUpdated')) {
            final lat = double.tryParse(data['latitude']?.toString() ?? '');
            final lng = double.tryParse(data['longitude']?.toString() ?? '');
            if (lat != null && lng != null && mounted) {
              setState(() {
                _deliveryLat = lat;
                _deliveryLng = lng;
              });
            }
          }
          if (eventName.contains('OrderStatusChanged')) {
            _loadOrder();
          }
        },
      );
      _trackingSubscribed = true;
      _loadInitialTracking();
    }
  }

  Future<void> _loadInitialTracking() async {
    if (_order == null || !_isTrackableStatus(_order!.status)) return;
    try {
      final data = await OrderService().getOrderTracking(widget.orderId);
      final lat = data['latitude'] is double ? data['latitude'] as double : (data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null);
      final lng = data['longitude'] is double ? data['longitude'] as double : (data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null);
      if (mounted && lat != null && lng != null) {
        setState(() {
          _deliveryLat = lat;
          _deliveryLng = lng;
        });
      }
    } catch (_) {
      // Sin ubicación inicial; se actualizará por Pusher
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await OrderService().getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
        _subscribeToTracking();
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

  Future<void> _uploadProof() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    String? paymentMethod;
    String? referenceNumber;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UploadProofDialog(),
    );
    if (result == null || !mounted) return;

    paymentMethod = result['method'];
    referenceNumber = result['ref'];
    if (paymentMethod == null || paymentMethod.isEmpty ||
        referenceNumber == null || referenceNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes ingresar método de pago y número de referencia')),
        );
      }
      return;
    }

    setState(() => _updating = true);
    try {
      await OrderService().uploadPaymentProof(
        widget.orderId,
        file.path,
        'jpeg',
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
      );
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante subido correctamente'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar orden'),
        content: const Text('¿Estás seguro de que deseas cancelar esta orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await OrderService().cancelOrder(widget.orderId, reason: 'Cancelación por usuario');
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden cancelada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    return path.startsWith('/') ? '$base/storage/$path' : '$base/storage/$path';
  }

  bool get _canCancel {
    if (_order == null) return false;
    if (_order!.status != 'pending_payment') return false;
    final limit = _order!.createdAt.add(const Duration(minutes: 5));
    return DateTime.now().isBefore(limit);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de orden')),
        body: const Center(child: CircularProgressIndicator()),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error ?? 'Orden no encontrada', textAlign: TextAlign.center),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardBg(context) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0);
    final badgeBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9);
    final scaffoldBg = isDark ? AppColors.backgroundDark : const Color(0xFFF5F7F8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Detalle del Recibo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
        centerTitle: true,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: _updating
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrder,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildReceiptHeader(order, textPrimary: textPrimary, textSecondary: textSecondary, surfaceColor: surfaceColor, borderColor: borderColor, badgeBg: badgeBg),
                    const SizedBox(height: 24),
                    _buildResumenCard(order, textPrimary: textPrimary, textSecondary: textSecondary, surfaceColor: surfaceColor, borderColor: borderColor, badgeBg: badgeBg),
                    const SizedBox(height: 24),
                    _buildPaymentAndAddressCard(order, textPrimary: textPrimary, textSecondary: textSecondary, surfaceColor: surfaceColor, borderColor: borderColor, badgeBg: badgeBg),
                    if (_isTrackableStatus(order.status)) ...[
                      const SizedBox(height: 24),
                      _buildTrackingCard(order),
                    ],
                    if (order.status == 'pending_payment') ...[
                      const SizedBox(height: 24),
                      _buildPendingPaymentActions(order),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(order, surfaceColor: surfaceColor, borderColor: borderColor),
    );
  }

  Widget _buildReceiptHeader(Order order, {required Color textPrimary, required Color textSecondary, required Color surfaceColor, required Color borderColor, required Color badgeBg}) {
    final commerceName = order.commerce?['business_name']?.toString() ?? 'Comercio';
    final commerceImage = order.commerce?['image']?.toString();
    final imageUrl = commerceImage != null && commerceImage.isNotEmpty
        ? (commerceImage.startsWith('http') ? commerceImage : _imageUrl(commerceImage))
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _commercePlaceholder(bgColor: badgeBg),
            ),
          )
        else
          _commercePlaceholder(bgColor: badgeBg),
        const SizedBox(height: 16),
        Text(
          commerceName,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _formatReceiptDate(order.createdAt),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ORDEN ID: ',
                style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Text(
                '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Color(0xFF3399FF)),
                onPressed: () {
                  final text = order.orderNumber.isNotEmpty ? order.orderNumber : '#${order.id}';
                  Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID copiado al portapapeles')),
                    );
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _commercePlaceholder({Color? bgColor}) {
    final bg = bgColor ?? const Color(0xFFF1F5F9);
    final border = bgColor ?? const Color(0xFFE2E8F0);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Icon(Icons.store, size: 40, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF94A3B8)),
    );
  }

  String _formatReceiptDate(DateTime d) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final h = d.hour;
    final am = h < 12;
    final hour = am ? (h == 0 ? 12 : h) : (h == 12 ? 12 : h - 12);
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} • $hour:$min ${am ? 'AM' : 'PM'}';
  }

  Widget _buildResumenCard(Order order, {required Color textPrimary, required Color textSecondary, required Color surfaceColor, required Color borderColor, required Color badgeBg}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 20),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          if (item.specialInstructions != null &&
                              item.specialInstructions!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.specialInstructions!,
                              style: TextStyle(fontSize: 13, color: textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          _buildDashedDivider(borderColor: borderColor),
          const SizedBox(height: 16),
          _resumenRow('Subtotal', order.subtotal, textPrimary: textPrimary, textSecondary: textSecondary),
          _resumenRow('Tarifa de entrega', order.deliveryFee, textPrimary: textPrimary, textSecondary: textSecondary),
          _resumenRow('Impuestos', order.tax, textPrimary: textPrimary, textSecondary: textSecondary),
          _resumenRow('Tarifa de servicio', 0, textPrimary: textPrimary, textSecondary: textSecondary),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Divider(height: 1, color: borderColor),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider({Color? borderColor}) {
    final color = borderColor ?? const Color(0xFFE2E8F0);
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 8.0;
        const gap = 6.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: gap),
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _resumenRow(String label, double value, {required Color textPrimary, required Color textSecondary}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: textSecondary)),
          Text('\$${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPaymentAndAddressCard(Order order, {required Color textPrimary, required Color textSecondary, required Color surfaceColor, required Color borderColor, required Color badgeBg}) {
    final paymentLabel = _paymentMethodLabel(order.paymentMethod);
    final paymentDisplay = order.referenceNumber?.isNotEmpty == true
        ? '${paymentLabel.isNotEmpty ? '$paymentLabel • ' : ''}•••• ${order.referenceNumber!.length >= 4 ? order.referenceNumber!.substring(order.referenceNumber!.length - 4) : order.referenceNumber}'
        : (paymentLabel.isEmpty ? 'Pago pendiente' : paymentLabel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.credit_card, color: textSecondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Método de pago', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                    Text(paymentDisplay, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: borderColor),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.location_on, color: textSecondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dirección de entrega', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                    Text(order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      case 'pago_movil':
        return 'Pago móvil';
      default:
        return method.isEmpty ? '' : method;
    }
  }

  Future<void> _onDownloadPdf(Order order) async {
    if (!mounted) return;
    setState(() => _updating = true);
    try {
      Uint8List? logoBytes;
      try {
        final data = await rootBundle.load('assets/images/logo_login.png');
        logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.offsetInBytes + data.lengthInBytes);
      } catch (_) {}

      if (order.receiptUrl != null && order.receiptUrl!.isNotEmpty) {
        try {
          final url = order.receiptUrl!.startsWith('http')
              ? order.receiptUrl!
              : '${AppConfig.apiUrl}/${order.receiptUrl!.replaceFirst('/', '')}';
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abriendo recibo...'), backgroundColor: Colors.green),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo abrir el enlace. Generando PDF...'), backgroundColor: Colors.orange),
            );
          }
          final bytes = await ReceiptPdfBuilder.build(order, logoImageBytes: logoBytes);
          if (bytes != null && mounted) {
            await Printing.sharePdf(bytes: bytes, filename: 'recibo-${order.id}.pdf');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF listo para guardar o compartir'), backgroundColor: Colors.green),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al generar el PDF'), backgroundColor: Colors.red),
            );
          }
        }
        return;
      }
      final bytes = await ReceiptPdfBuilder.build(order, logoImageBytes: logoBytes);
      if (bytes == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al generar el PDF'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      await Printing.sharePdf(bytes: bytes, filename: 'recibo-${order.id}.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF listo para guardar o compartir'), backgroundColor: Colors.green),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Widget _buildBottomBar(Order order, {required Color surfaceColor, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _updating ? null : () => _onDownloadPdf(order),
            icon: _updating ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download, size: 22),
            label: Text(_updating ? 'Generando...' : 'Descargar PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3399FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentActions(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pendiente de pago',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _uploadProof,
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir comprobante de pago'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentButton(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar orden'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  bool _isTrackableStatus(String status) {
    return status == 'shipped' || status == 'out_for_delivery' || status == 'processing' || status == 'paid';
  }

  Widget _buildTrackingCard(Order order) {
    final hasLocation = _deliveryLat != null && _deliveryLng != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? null : Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delivery_dining, color: AppColors.green, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Seguimiento de entrega',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasLocation)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: OsmMapWidget(
                      center: LatLng(_deliveryLat!, _deliveryLng!),
                      zoom: 15.0,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_searching, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Esperando ubicación del repartidor...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Ver en Google Maps'),
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps?q=$_deliveryLat,$_deliveryLng',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _UploadProofDialog extends StatefulWidget {
  const _UploadProofDialog();

  @override
  State<_UploadProofDialog> createState() => _UploadProofDialogState();
}

class _UploadProofDialogState extends State<_UploadProofDialog> {
  final _refController = TextEditingController();
  String _selectedMethod = 'transferencia';

  static const List<String> _methods = [
    'efectivo',
    'transferencia',
    'tarjeta',
    'pago_movil',
    'otro',
  ];

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subir comprobante'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresa los datos del pago realizado:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: _methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(_methodLabel(m))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMethod = v ?? 'transferencia'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Número de referencia / transacción',
                border: OutlineInputBorder(),
                hintText: 'Ej: REF123456',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final ref = _refController.text.trim();
            if (ref.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingresa número de referencia')),
              );
              return;
            }
            Navigator.pop(context, {'method': _selectedMethod, 'ref': ref});
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      case 'pago_movil':
        return 'Pago móvil';
      default:
        return m;
    }
  }
}
