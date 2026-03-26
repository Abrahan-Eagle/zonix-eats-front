import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/receipt_pdf_builder.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/widgets/osm_map_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/l10n/app_strings.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/screens/orders/order_rating_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.order,
    this.showCreatedDialog = false,
  });

  final int orderId;
  final Order? order;
  /// Si true, al abrir la pantalla se muestra un modal "¡Pedido creado!" y se va directo al detalle del recibo.
  final bool showCreatedDialog;

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
  StreamSubscription<Map<String, dynamic>>? _pusherSubscription;
  String? _selectedPaymentMethodLabel;

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
    if (widget.showCreatedDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCreatedDialog());
    }
  }

  void _showCreatedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Pedido creado!'),
        content: const Text(
          'Tu orden está pendiente. El comercio la revisará y cuando la acepte podrás subir el comprobante de pago aquí.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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
    _pusherSubscription?.cancel();
    if (_trackingSubscribed) {
      PusherService.instance
          .unsubscribeFromChannel('private-orders.${widget.orderId}');
    }
    super.dispose();
  }

  void _subscribeToTracking() {
    if (_order == null || _trackingSubscribed) {
      return;
    }
    final s = _order!.status;
    final shouldSubscribe = s == 'shipped' ||
        s == 'out_for_delivery' ||
        s == 'processing' ||
        s == 'paid' ||
        s == 'pending_payment';
    if (shouldSubscribe) {
      PusherService.instance.subscribeToOrderChat(widget.orderId);
      
      _pusherSubscription?.cancel();
      _pusherSubscription = PusherService.instance.eventStream.listen((event) {
        final eventName = event['eventName']?.toString() ?? '';
        final channelName = event['channelName']?.toString() ?? '';
        final data = event['data'] is Map<String, dynamic>
            ? event['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        if (eventName.contains('NotificationCreated') && mounted) {
          final notifData = data['data'] is Map ? data['data'] as Map : {};
          if (notifData['action'] == 'show_delivery_qr' &&
              notifData['order_id']?.toString() == widget.orderId.toString()) {
            _showDeliveryQrModal();
          }
        }

        if (channelName != 'private-orders.${widget.orderId}') return;

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
        
        if (eventName.contains('OrderStatusChanged') || 
            eventName.contains('PaymentValidated')) {
          _loadOrder();
          if (data['status'] == 'delivered' && mounted) {
            _showRatingAfterDelivery();
          }
        }
      });

      _trackingSubscribed = true;
      if (_isTrackableStatus(s)) {
        _loadInitialTracking();
      }
    }
  }

  Future<void> _loadInitialTracking() async {
    if (_order == null || !_isTrackableStatus(_order!.status)) return;
    try {
      final data = await OrderService().getOrderTracking(widget.orderId);
      final lat = data['latitude'] is double
          ? data['latitude'] as double
          : (data['latitude'] != null
              ? double.tryParse(data['latitude'].toString())
              : null);
      final lng = data['longitude'] is double
          ? data['longitude'] as double
          : (data['longitude'] != null
              ? double.tryParse(data['longitude'].toString())
              : null);
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

  Future<void> _uploadProof(Order order, {String type = 'food'}) async {
    String? paymentMethod;
    String? referenceNumber;
    String? imagePath;

    List<Map<String, dynamic>> availableMethods = [];
    try {
      if (type == 'delivery') {
        final info = await OrderService().getPaymentInfo(widget.orderId);
        availableMethods = List<Map<String, dynamic>>.from(info?['delivery_methods'] ?? []);
      } else {
        availableMethods = await OrderService().getAvailablePaymentMethodsForOrder(widget.orderId);
      }
    } catch (_) {}
    if (!mounted) return;

    final dialogTitle = type == 'delivery' ? 'Pagar envío' : 'Pagar comida';
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UploadProofDialog(
        paymentMethods: availableMethods,
        initialMethod: _selectedPaymentMethodLabel,
        title: dialogTitle,
      ),
    );
    if (result == null || !mounted) return;

    paymentMethod = result['method'];
    imagePath = result['image_path'];
    var rawRef = result['ref']?.trim() ?? '';
    rawRef = rawRef.replaceAll(RegExp(r'\D'), '');
    referenceNumber = rawRef;

    if (paymentMethod == null || paymentMethod.isEmpty || referenceNumber.isEmpty || imagePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos incompletos para subir el comprobante')));
      }
      return;
    }

    setState(() => _updating = true);
    try {
      final ext = imagePath.split('.').last.toLowerCase();
      final fileType = (ext == 'png') ? 'png' : 'jpeg';

      await OrderService().uploadPaymentProof(
        widget.orderId,
        imagePath,
        fileType,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        type: type,
      );
      await _loadOrder();
      if (mounted) {
        final label = type == 'delivery' ? 'envío' : 'comida';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comprobante de $label subido correctamente'), backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: AppColors.red),
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
    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _updating = true);
    try {
      await OrderService()
          .cancelOrder(widget.orderId, reason: 'Cancelación por usuario');
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
      if (mounted) {
        setState(() => _updating = false);
      }
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
        appBar: AppBar(title: const Text(AppStrings.orderDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.orderDetailTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error ?? AppStrings.orderNotFound,
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardBg(context) : AppColors.white;
    final textPrimary = AppColors.primaryText(context);
    final textSecondary = AppColors.secondaryText(context);
    final borderColor = isDark ? AppColors.grayDark : AppColors.grayLight;
    final badgeBg = isDark ? AppColors.grayDark : AppColors.grayLight;
    final scaffoldBg = AppColors.scaffoldBg(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppStrings.receiptDetailTitle,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Chat con el comercio',
            icon: Icon(Icons.chat_bubble_outline, color: textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BuyerOrderChatPage(orderId: order.id),
                ),
              );
            },
          ),
        ],
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.transparent,
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
                    _buildReceiptHeader(order,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        badgeBg: badgeBg),
                    if (_isTrackableStatus(order.status)) ...[
                      const SizedBox(height: 24),
                      _buildActiveOrderProgressSection(
                          order, primary: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.accentButton(context)
                              : AppColors.blue,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary),
                    ],
                    const SizedBox(height: 24),
                    _buildResumenCard(order,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        badgeBg: badgeBg),
                    const SizedBox(height: 24),
                    _buildPaymentAndAddressCard(order,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        badgeBg: badgeBg),
                    if (_isTrackableStatus(order.status) && order.isDeliveryOrder) ...[
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
      bottomNavigationBar: order.paymentValidatedAt != null
          ? _buildBottomBar(order,
              surfaceColor: surfaceColor, borderColor: borderColor)
          : null,
    );
  }

  Widget _buildReceiptHeader(Order order,
      {required Color textPrimary,
      required Color textSecondary,
      required Color surfaceColor,
      required Color borderColor,
      required Color badgeBg}) {
    final commerceName =
        order.commerce?['business_name']?.toString() ?? 'Comercio';
    final commerceImage = order.commerce?['image']?.toString();
    final imageUrl = commerceImage != null && commerceImage.isNotEmpty
        ? (commerceImage.startsWith('http')
            ? commerceImage
            : _imageUrl(commerceImage))
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
              errorBuilder: (_, __, ___) =>
                  _commercePlaceholder(bgColor: badgeBg),
            ),
          )
        else
          _commercePlaceholder(bgColor: badgeBg),
        const SizedBox(height: 16),
        Text(
          commerceName,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _formatReceiptDate(order.createdAt),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
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
                color: AppColors.black.withValues(alpha: 0.04),
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
                style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              Text(
                '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: AppColors.blue),
                onPressed: () {
                  final text = order.orderNumber.isNotEmpty
                      ? order.orderNumber
                      : '#${order.id}';
                  Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ID copiado al portapapeles')),
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
    final bg = bgColor ?? AppColors.grayLight;
    final border = bgColor ?? AppColors.grayLight;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Icon(Icons.store,
          size: 40,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white54
              : AppColors.gray),
    );
  }

  String _formatReceiptDate(DateTime d) {
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
    final h = d.hour;
    final am = h < 12;
    final hour = am ? (h == 0 ? 12 : h) : (h == 12 ? 12 : h - 12);
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} • $hour:$min ${am ? 'AM' : 'PM'}';
  }

  Widget _buildResumenCard(Order order,
      {required Color textPrimary,
      required Color textSecondary,
      required Color surfaceColor,
      required Color borderColor,
      required Color badgeBg}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
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
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 20),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textSecondary),
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
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary),
                          ),
                          if (item.specialInstructions != null &&
                              item.specialInstructions!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.specialInstructions!,
                              style:
                                  TextStyle(fontSize: 13, color: textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary),
                    ),
                  ],
                ),
              )),
          if (order.specialInstructions != null &&
              order.specialInstructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDashedDivider(borderColor: borderColor),
            const SizedBox(height: 12),
            Text(
              'Notas del pedido',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.specialInstructions!,
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
            ),
          ],
          const SizedBox(height: 16),
          _buildDashedDivider(borderColor: borderColor),
          const SizedBox(height: 16),
          _resumenRow('Subtotal', order.subtotal,
              textPrimary: textPrimary, textSecondary: textSecondary),
          _resumenRow('Tarifa de entrega', order.deliveryFee,
              textPrimary: textPrimary, textSecondary: textSecondary),
          _resumenRow('Impuestos', order.tax,
              textPrimary: textPrimary, textSecondary: textSecondary),
          _resumenRow('Tarifa de servicio', 0,
              textPrimary: textPrimary, textSecondary: textSecondary),
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
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider({Color? borderColor}) {
    final color = borderColor ?? AppColors.grayLight;
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

  Widget _resumenRow(String label, double value,
      {required Color textPrimary, required Color textSecondary}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: textSecondary)),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary)),
        ],
      ),
    );
  }

  /// Formatea método + referencia desde un item de order_payments (food o delivery).
  String _paymentDisplayFromMap(Map<String, dynamic>? p) {
    if (p == null) return '';
    final label = (p['payment_method_label'] as String?)?.trim() ?? '';
    final ref = p['reference_number'] as String?;
    if (ref != null && ref.isNotEmpty) {
      final last4 = ref.length >= 4 ? ref.substring(ref.length - 4) : ref;
      return label.isNotEmpty ? '$label •••• $last4' : '•••• $last4';
    }
    return label.isNotEmpty ? label : '';
  }

  Widget _buildPaymentAndAddressCard(Order order,
      {required Color textPrimary,
      required Color textSecondary,
      required Color surfaceColor,
      required Color borderColor,
      required Color badgeBg}) {
    final approved = order.approvedForPayment;
    final paymentLabel = _paymentMethodLabel(order.paymentMethod);
    final paymentDisplay = order.referenceNumber?.isNotEmpty == true
        ? '${paymentLabel.isNotEmpty ? '$paymentLabel • ' : ''}•••• ${order.referenceNumber!.length >= 4 ? order.referenceNumber!.substring(order.referenceNumber!.length - 4) : order.referenceNumber}'
        : (_selectedPaymentMethodLabel ??
            (paymentLabel.isEmpty ? (approved ? 'Seleccionar pago' : 'Esperando aprobación') : paymentLabel));

    final useDoublePayment = order.orderPayments.isNotEmpty && order.foodPayment != null;
    final foodLine = useDoublePayment ? _paymentDisplayFromMap(order.foodPayment) : null;
    final deliveryLine = useDoublePayment && order.deliveryPaymentData != null
        ? _paymentDisplayFromMap(order.deliveryPaymentData)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
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
                child: Icon(Icons.credit_card, color: textSecondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (useDoublePayment) ...[
                      Text('Pago comida (comercio)',
                          style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        foodLine?.isNotEmpty == true ? foodLine! : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (deliveryLine != null) ...[
                        const SizedBox(height: 12),
                        Text('Pago envío (empresa de delivery)',
                            style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          deliveryLine.isNotEmpty ? deliveryLine : '—',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ] else ...[
                      Text('Método de pago',
                          style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        paymentDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (order.status == 'pending_payment' && order.approvedForPayment) ...[
                      if (!order.hasFoodProof)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _uploadProof(order, type: 'food'),
                              icon: const Icon(Icons.receipt_long, size: 20),
                              label: const Text('Pagar comida'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        )
                      else if (!order.foodValidated && !order.foodRejected)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Comprobante comida subido. Esperando validación del comercio.',
                            style: TextStyle(fontSize: 12, color: AppColors.orange),
                          ),
                        )
                      else if (order.foodRejected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pago comida rechazado.', style: TextStyle(fontSize: 12, color: AppColors.red)),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _uploadProof(order, type: 'food'),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Re-subir comprobante comida'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Pago comida validado', style: TextStyle(fontSize: 12, color: AppColors.green)),
                        ),
                      if (order.needsDeliveryPayment) ...[
                        const SizedBox(height: 8),
                        if (!order.hasDeliveryProof)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _uploadProof(order, type: 'delivery'),
                              icon: const Icon(Icons.local_shipping, size: 20),
                              label: Text('Pagar envío (\$${order.deliveryFee.toStringAsFixed(2)})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          )
                        else if (!order.deliveryValidated && !order.deliveryRejected)
                          const Text(
                            'Comprobante envío subido. Esperando validación de la empresa.',
                            style: TextStyle(fontSize: 12, color: AppColors.orange),
                          )
                        else if (order.deliveryRejected)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pago envío rechazado.', style: TextStyle(fontSize: 12, color: AppColors.red)),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _uploadProof(order, type: 'delivery'),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Re-subir comprobante envío'),
                                ),
                              ),
                            ],
                          )
                        else
                          const Text('Pago envío validado', style: TextStyle(fontSize: 12, color: AppColors.green)),
                      ],
                    ],
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
                    Text(order.isPickup ? 'Retiro en tienda' : 'Dirección de entrega',
                        style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500)),
                    Text(
                        order.isPickup
                            ? (order.commerceName.isNotEmpty
                                ? order.commerceName
                                : 'Recoger en el comercio')
                            : (order.deliveryAddress.isEmpty
                                ? '—'
                                : order.deliveryAddress),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
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

  /// Genera el PDF del recibo con los datos de la orden y abre la hoja de compartir
  /// (guardar, WhatsApp, etc.). Siempre usa ReceiptPdfBuilder para imprimir los valores.
  Future<void> _onDownloadPdf(Order order) async {
    if (!mounted) return;
    setState(() => _updating = true);
    try {
      Uint8List? logoBytes;
      try {
        final data = await rootBundle.load('assets/images/logo_login.png');
        logoBytes = data.buffer.asUint8List(
            data.offsetInBytes, data.offsetInBytes + data.lengthInBytes);
      } catch (_) {}

      final bytes =
          await ReceiptPdfBuilder.build(order, logoImageBytes: logoBytes);
      if (bytes == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error al generar el PDF'),
                backgroundColor: AppColors.red),
          );
        }
        return;
      }
      await Printing.sharePdf(bytes: bytes, filename: 'recibo-${order.id}.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PDF listo para guardar o compartir'),
            backgroundColor: AppColors.green),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Widget _buildBottomBar(Order order,
      {required Color surfaceColor, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
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
            icon: _updating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white))
                : const Icon(Icons.download, size: 22),
            label: Text(
                _updating ? AppStrings.generating : AppStrings.downloadPdf),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentActions(Order order) {
    final hasProof = order.paymentProof != null && order.paymentProof!.isNotEmpty;
    final approvedForPayment = order.approvedForPayment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hasProof ? 'Comprobante enviado' : 'Pendiente de pago',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
        ),
        const SizedBox(height: 8),
        if (!approvedForPayment) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esperando que el comercio acepte tu pedido. Cuando lo acepte, aparecerá el botón para subir el comprobante.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (hasProof) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Comprobante subido y esperando validación.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else
          const SizedBox.shrink(),
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

  int _progressStep(Order order) {
    final s = order.status.toLowerCase();
    switch (s) {
      case 'pending_payment':
      case 'pending':
      case 'paid':
        return 0;
      case 'processing':
      case 'preparing':
      case 'ready':
        return 1;
      case 'shipped':
      case 'out_for_delivery':
      case 'on_way':
        return 2;
      case 'delivered':
        return 3;
      default:
        if (s.contains('camino') || s.contains('shipped') || s.contains('delivery')) return 2;
        if (s.contains('prepar') || s.contains('process') || s.contains('ready')) return 1;
        if (s.contains('entreg') || s.contains('delivered')) return 3;
        return 0;
    }
  }

  Widget _buildActiveOrderProgressSection(Order order,
      {required Color primary,
      required Color surfaceColor,
      required Color borderColor,
      required Color textPrimary,
      required Color textSecondary}) {
    final step = _progressStep(order);
    final labels = order.isPickup
        ? const ['RECIBIDO', 'PREPARACIÓN', 'LISTO', 'RECOGIDO']
        : const ['RECIBIDO', 'PREPARACIÓN', 'EN CAMINO', 'ENTREGADO'];
    final icons = order.isPickup
        ? const [Icons.check, Icons.restaurant, Icons.storefront, Icons.shopping_bag]
        : const [Icons.check, Icons.restaurant, Icons.two_wheeler, Icons.inventory_2];
    Widget circle(int i) {
      final done = i < step;
      final active = i == step;
      return Container(
        width: active ? 40 : 32,
        height: active ? 40 : 32,
        decoration: BoxDecoration(
          color: done || active ? primary : textSecondary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
        child: Icon(
          icons[i],
          size: active ? 20 : 16,
          color: (done || active) ? AppColors.white : textSecondary,
        ),
      );
    }
    Color labelColor(int i) => i <= step ? primary : textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (step) {
              0 => 'Recibido',
              1 => 'En preparación',
              2 => order.isPickup ? 'Listo para recoger' : 'En camino',
              3 => order.isPickup ? 'Recogido' : 'Entregado',
              _ => 'Recibido',
            },
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Column(children: [
                circle(0),
                const SizedBox(height: 6),
                Text(labels[0], style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: labelColor(0))),
              ]),
              Expanded(
                child: Center(
                  child: Container(
                    height: 2,
                    color: step > 0 ? primary : textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Column(children: [
                circle(1),
                const SizedBox(height: 6),
                Text(labels[1], style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: labelColor(1))),
              ]),
              Expanded(
                child: Center(
                  child: Container(
                    height: 2,
                    color: step > 1 ? primary : textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Column(children: [
                circle(2),
                const SizedBox(height: 6),
                Text(labels[2], style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: labelColor(2))),
              ]),
              Expanded(
                child: Center(
                  child: Container(
                    height: 2,
                    color: step > 2 ? primary : textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Column(children: [
                circle(3),
                const SizedBox(height: 6),
                Text(labels[3], style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: labelColor(3))),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'El avance lo marca el comercio. Desliza hacia abajo para actualizar.',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeliveryQrModal() async {
    final qr = await OrderService().getDeliveryQrPayload(widget.orderId);
    if (!mounted || qr == null) return;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delivery_dining, size: 48, color: AppColors.green),
              const SizedBox(height: 12),
              Text(
                'El repartidor llegó',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Muestra este QR al repartidor para confirmar la entrega',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qr,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'El repartidor escaneará este código',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingAfterDelivery() {
    if (_order == null) return;
    // Close QR modal if open
    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == null);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        useSafeArea: true,
        backgroundColor: AppColors.transparent,
        builder: (ctx) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: OrderRatingPage(order: _order!),
          ),
        ),
      ).then((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    });
  }

  bool _isTrackableStatus(String status) {
    return status == 'pending_payment' ||
        status == 'shipped' ||
        status == 'out_for_delivery' ||
        status == 'processing' ||
        status == 'paid';
  }

  Widget _buildTrackingCard(Order order) {
    final hasLocation = _deliveryLat != null && _deliveryLng != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? null : AppColors.white,
      surfaceTintColor: AppColors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delivery_dining,
                    color: AppColors.green, size: 22),
                const SizedBox(width: 8),
                Text(
                  AppStrings.deliveryTracking,
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
                  color: isDark ? AppColors.grayDark : AppColors.white,
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
                  color: isDark
                      ? AppColors.gray.withValues(alpha: 0.1)
                      : AppColors.grayLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_searching,
                        size: 36, color: AppColors.gray),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.waitingDeliveryLocation,
                      style: TextStyle(color: AppColors.gray, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (order.status == 'shipped' || order.status == 'out_for_delivery') ...[
              const SizedBox(height: 12),
              Text(
                'Cuando el repartidor llegue, te pedirá mostrar tu QR',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
                textAlign: TextAlign.center,
              ),
            ],
            if (hasLocation) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text(AppStrings.openInGoogleMaps),
                  onPressed: () async {
                    final url = Uri.parse(
                      '${AppConfig.googleMapsPointUrl}=$_deliveryLat,$_deliveryLng',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
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
  final List<Map<String, dynamic>> paymentMethods;
  final String? initialMethod;
  final String title;
  const _UploadProofDialog({required this.paymentMethods, this.initialMethod, this.title = 'Pagar y notificar'});

  @override
  State<_UploadProofDialog> createState() => _UploadProofDialogState();
}

class _UploadProofDialogState extends State<_UploadProofDialog> {
  final _refController = TextEditingController();
  late String _selectedMethod;
  int _currentStep = 0; // 0: Info, 1: Upload
  XFile? _image;
  bool _pickingImage = false;

  static const List<String> _fallbackMethods = [
    'efectivo',
    'transferencia',
    'tarjeta',
    'pago_movil',
    'otro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMethod != null) {
      _selectedMethod = widget.initialMethod!;
    } else if (widget.paymentMethods.isNotEmpty) {
      _selectedMethod =
          (widget.paymentMethods.first['type'] ?? 'other') as String;
    } else {
      _selectedMethod = 'transferencia';
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _image = file);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      setState(() => _pickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useCommerceMethods = widget.paymentMethods.isNotEmpty;
    final items = useCommerceMethods
        ? widget.paymentMethods
            .map((m) => DropdownMenuItem<String>(
                  value: (m['type'] ?? 'other') as String,
                  child: Text((m['label'] ?? m['type'] ?? '—').toString()),
                ))
            .toList()
        : _fallbackMethods
            .map((m) => DropdownMenuItem(value: m, child: Text(_methodLabel(m))))
            .toList();

    final mq = MediaQuery.sizeOf(context);
    final dialogWidth = mq.width - 32;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      title: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _currentStep == 0 ? 'Datos de pago' : 'Reportar pago',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildStepIndicator(),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SingleChildScrollView(
            key: ValueKey<int>(_currentStep),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              if (_currentStep == 0) ...[
                Text(
                  useCommerceMethods
                      ? 'Transfiere o deposita a estas cuentas:'
                      : 'Ingresa los datos del pago realizado:',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText(context).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: items.any((e) => e.value == _selectedMethod)
                      ? _selectedMethod
                      : (items.isNotEmpty ? items.first.value : null),
                  decoration: InputDecoration(
                    labelText: 'Método de pago',
                    filled: true,
                    fillColor: AppColors.grayLight.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: items,
                  onChanged: (v) =>
                      setState(() => _selectedMethod = v ?? _selectedMethod),
                ),
                if (useCommerceMethods) ...[
                  const SizedBox(height: 16),
                  _buildSelectedMethodDetails(),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Nota: Guarda el número de referencia y captura el comprobante para el siguiente paso.',
                    style: TextStyle(fontSize: 12, color: AppColors.blue, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                // Paso 1: Carga
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _methodLabel(_selectedMethod),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _refController,
                  decoration: InputDecoration(
                    labelText: 'Número de referencia',
                    hintText: 'Ej: 466511',
                    helperText: 'Últimos 4-6 dígitos del pago',
                    filled: true,
                    fillColor: AppColors.grayLight.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.tag, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Imagen del comprobante', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_image != null)
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            width: double.infinity,
                            child: Image.file(
                              File(_image!.path),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 180,
                                color: AppColors.grayLight,
                                child: const Icon(Icons.broken_image, color: AppColors.gray, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _image = null),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: _pickingImage ? null : _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.blue.withValues(alpha: 0.2),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_pickingImage)
                            const CircularProgressIndicator(strokeWidth: 2)
                          else ...[
                            const Icon(Icons.add_a_photo, size: 40, color: AppColors.blue),
                            const SizedBox(height: 12),
                            const Text(
                              'Galería de fotos',
                              style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            if (_currentStep == 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Ya pagué'),
                ),
              ),
            ] else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final ref = _refController.text.trim();
                    if (ref.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La referencia debe tener entre 4 y 6 dígitos')),
                      );
                      return;
                    }
                    if (_image == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona una imagen')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'method': _selectedMethod,
                      'ref': ref,
                      'image_path': _image!.path,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Enviar'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(0, 'Info'),
        Container(
          width: 40,
          height: 2,
          color: _currentStep == 1 ? AppColors.blue : AppColors.grayLight,
        ),
        _stepCircle(1, 'Subir'),
      ],
    );
  }

  Widget _stepCircle(int step, String label) {
    bool active = _currentStep >= step;
    bool current = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? AppColors.blue : AppColors.grayLight,
            shape: BoxShape.circle,
            border: current ? Border.all(color: AppColors.blue.withValues(alpha: 0.3), width: 4) : null,
          ),
          child: Center(
            child: Text(
              (step + 1).toString(),
              style: TextStyle(
                color: active ? AppColors.white : AppColors.primaryText(context).withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.blue : AppColors.primaryText(context).withValues(alpha: 0.5),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMethodDetails() {
    final m = widget.paymentMethods.firstWhere(
      (e) => (e['type'] ?? 'other') == _selectedMethod,
      orElse: () => {},
    );
    if (m.isEmpty) return const SizedBox.shrink();

    final bankName = (m['bank_name'] ?? m['bank']?['name'] ?? '').toString();
    final accountNumber = (m['account_number'] ?? '').toString();
    final phone = (m['phone'] ?? '').toString();
    final ownerName = (m['owner_name'] ?? '').toString();
    // Backend: owner_id en BD; también number_ci / rif_number en payload o reference_info
    final idNumber = (m['owner_id'] ??
            m['rif_number'] ??
            m['number_ci'] ??
            m['id_number'] ??
            m['id_document'] ??
            '')
        .toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Datos de destino',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bankName.isNotEmpty) _detailRow('Banco', bankName, isCopyable: true),
          if (accountNumber.isNotEmpty) _detailRow('Cuenta', accountNumber, isCopyable: true),
          if (phone.isNotEmpty) _detailRow('Teléfono', phone, isCopyable: true),
          if (idNumber.isNotEmpty)
            _detailRow(
              _isMobilePaymentType(_selectedMethod) ? 'Cédula / RIF' : 'ID fiscal',
              idNumber,
              isCopyable: true,
            ),
          if (ownerName.isNotEmpty) _detailRow('Titular', ownerName, isCopyable: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedGray, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              if (isCopyable)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copiado'), duration: const Duration(seconds: 1)),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isMobilePaymentType(String type) {
    final t = type.toLowerCase();
    return t == 'pago_movil' || t == 'mobile_payment';
  }

  String _methodLabel(String m) {
    switch (m.toLowerCase()) {
      case 'efectivo':
      case 'cash':
        return 'Efectivo';
      case 'transferencia':
      case 'bank_transfer':
        return 'Transferencia bancaria';
      case 'tarjeta':
      case 'card':
        return 'Tarjeta';
      case 'pago_movil':
      case 'mobile_payment':
        return 'Pago móvil';
      default:
        if (m.isEmpty) return m;
        return m.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
    }
  }
}
