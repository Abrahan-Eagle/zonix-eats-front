import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/orders/order_rating_page.dart';

class OrderHistoryDetailPage extends StatelessWidget {
  const OrderHistoryDetailPage({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = AppColors.scaffoldBg(context);
    final surface = AppColors.cardBg(context);
    final borderColor =
        isDark ? AppColors.grayDark : AppColors.grayLight.withValues(alpha: 0.7);
    final primary =
        isDark ? AppColors.accentButton(context) : AppColors.blue;
    final textPrimary = AppColors.primaryText(context);
    final textSecondary = AppColors.secondaryText(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        title: Text(
          'Detalle del Pedido',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primary: primary,
                  ),
                  const SizedBox(height: 16),
                  _buildProducts(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primary: primary,
                  ),
                  const SizedBox(height: 16),
                  _buildDeliverySection(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primary: primary,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentSummary(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    primary: primary,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRepeatButton(context, primary),
                  const SizedBox(height: 8),
                  if (order.isDelivered) ...[
                    _buildRateButton(
                      context,
                      surface: surface,
                      textPrimary: textPrimary,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildReceiptButton(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color primary,
  }) {
    final commerceName =
        order.commerce?['business_name']?.toString() ?? 'Comercio';
    final commerceImage = order.commerce?['image']?.toString();
    final imageUrl = commerceImage != null && commerceImage.isNotEmpty
        ? commerceImage
        : null;

    final statusText = order.statusText;
    final isDelivered = order.isDelivered;
    final statusColor = isDelivered ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _placeholderImage(context, 80, 80),
                  )
                : _placeholderImage(context, 80, 80),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commerceName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatLongDate(order.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          Text(
            'Esta orden no tiene productos.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: textSecondary,
            ),
          )
        else
          Column(
            children: order.items
                .map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fastfood,
                            color: primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cantidad: ${item.quantity}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildDeliverySection(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.isPickup ? 'Retiro en tienda' : 'Entrega',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isPickup ? 'Recoger en' : 'Dirección de entrega',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.isPickup
                          ? (order.commerceName.isNotEmpty
                              ? order.commerceName
                              : 'Retirado en tienda')
                          : (order.deliveryAddress.isEmpty
                              ? '—'
                              : order.deliveryAddress),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de pago',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _summaryRow(
                'Subtotal',
                order.subtotal,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _summaryRow(
                'Tarifa de envío',
                order.deliveryFee,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _summaryRow(
                'Impuestos',
                order.tax,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatButton(BuildContext context, Color primary) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _repeatOrder(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.reorder, size: 20),
            const SizedBox(width: 8),
            Text(
              'Volver a pedir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptButton(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _openReceipt(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 20),
            const SizedBox(width: 8),
            Text(
              'Descargar recibo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateButton(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _openRatingModal(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rate_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Calificar pedido',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _repeatOrder(BuildContext context) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta orden no tiene ítems para agregar'),
        ),
      );
      return;
    }
    final cartService = Provider.of<CartService>(context, listen: false);
    for (final item in order.items) {
      cartService.addToCart(
        CartItem(
          id: item.productId,
          nombre: item.productName,
          precio: item.price,
          quantity: item.quantity,
          image: item.productImage.isNotEmpty ? item.productImage : null,
          imagen: item.productImage.isNotEmpty ? item.productImage : null,
          commerceId: order.commerceId,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${order.items.length} producto(s) agregados al carrito'),
      ),
    );
  }

  void _openReceipt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          orderId: order.id,
          order: order,
        ),
      ),
    );
  }

  void _openRatingModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: OrderRatingPage(order: order),
        ),
      ),
    );
  }

  String _formatLongDate(DateTime d) {
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
    return '${d.day} de ${months[d.month - 1]}, ${d.year}';
  }

  Widget _placeholderImage(BuildContext context, double w, double h) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: dark ? AppColors.grayDark : AppColors.grayLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.store,
        color: dark ? AppColors.white54 : AppColors.gray,
        size: w * 0.5,
      ),
    );
  }
}

