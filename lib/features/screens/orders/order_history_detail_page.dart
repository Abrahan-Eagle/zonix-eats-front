import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/order_rating_page.dart';
import 'package:zonix/features/screens/orders/receipt_pdf_builder.dart';

class OrderHistoryDetailPage extends StatefulWidget {
  const OrderHistoryDetailPage({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  State<OrderHistoryDetailPage> createState() => _OrderHistoryDetailPageState();
}

class _OrderHistoryDetailPageState extends State<OrderHistoryDetailPage> {
  late Order _order;
  bool _pdfSharing = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  static List<BoxShadow> _elevationShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
        blurRadius: isDark ? 16 : 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final surface = AppColors.cardBg(context);
    final textPrimary = AppColors.primaryText(context);
    final textSecondary = AppColors.secondaryText(context);
    final mutedBorder =
        isDark ? AppColors.white24 : AppColors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 24),
                  _buildProducts(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    mutedBorder: mutedBorder,
                  ),
                  const SizedBox(height: 24),
                  _buildDeliverySection(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 24),
                  _buildPaymentSummary(
                    context,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    mutedBorder: mutedBorder,
                  ),
                ],
              ),
            ),
          ),
          _buildFooterBar(
            context,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBar(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Material(
      elevation: 0,
      color: surface,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRepeatButton(context),
                const SizedBox(height: 12),
                if (_order.shouldShowRateButton) ...[
                  _buildRateButton(
                    context,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildReceiptButton(
                  context,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final commerceName =
        _order.commerce?['business_name']?.toString() ?? 'Comercio';
    final commerceImage = _order.commerce?['image']?.toString();
    final imageUrl = commerceImage != null && commerceImage.isNotEmpty
        ? commerceImage
        : null;

    final statusText = _order.statusText;
    final isDelivered = _order.isDelivered;
    final statusColor = isDelivered ? AppColors.green : AppColors.red;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _elevationShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(
                              context, 80, 80,
                              circular: true),
                        )
                      : _placeholderImage(context, 80, 80, circular: true),
                ),
                const SizedBox(height: 16),
                Text(
                  commerceName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatOrderDateTime(_order.createdAt),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDelivered ? Icons.check_circle : Icons.schedule,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
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
    required Color mutedBorder,
  }) {
    final cs = Theme.of(context).colorScheme;
    if (_order.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _elevationShadow(context),
        ),
        child: Text(
          'Esta orden no tiene productos.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _elevationShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: mutedBorder),
              ),
            ),
            child: Text(
              'TU PEDIDO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                for (var i = 0; i < _order.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 24),
                  _buildProductRow(
                    _order.items[i],
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    accentColor: cs.primary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(
    OrderItem item, {
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '${item.quantity}x',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              if (item.specialInstructions != null &&
                  item.specialInstructions!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.specialInstructions!.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$${item.total.toStringAsFixed(2)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleLabel = _order.isPickup ? 'RETIRO EN TIENDA' : 'DOMICILIO';
    final bodyBold = _order.isPickup
        ? (_order.commerceName.isNotEmpty
            ? _order.commerceName
            : 'Retiro en tienda')
        : (_order.deliveryAddress.isEmpty ? '—' : _order.deliveryAddress);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _elevationShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _order.isPickup ? Icons.storefront_outlined : Icons.location_on,
              color: cs.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bodyBold,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
    BuildContext context, {
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color mutedBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _elevationShadow(context),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Subtotal',
            _order.subtotal,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _summaryRow(
            'Tarifa de envío',
            _order.deliveryFee,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _summaryRow(
            'Impuestos',
            _order.tax,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: mutedBorder),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total pagado',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                '\$${_order.total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: () => _repeatOrder(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 22, color: cs.onPrimary),
            const SizedBox(width: 10),
            Text(
              'Volver a pedir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptButton(
    BuildContext context, {
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(
            color: textSecondary.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: _pdfSharing ? null : () => _openReceipt(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pdfSharing
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textPrimary,
                    ),
                  )
                : Icon(Icons.receipt_long, size: 22, color: textPrimary),
            const SizedBox(width: 10),
            Text(
              _pdfSharing ? 'Generando PDF…' : 'Descargar recibo',
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
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(
            color: textSecondary.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: () => _openRatingModal(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rate_rounded, size: 22, color: textPrimary),
            const SizedBox(width: 10),
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
              fontWeight: FontWeight.w500,
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
    if (_order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta orden no tiene ítems para agregar'),
        ),
      );
      return;
    }
    final cartService = Provider.of<CartService>(context, listen: false);
    for (final item in _order.items) {
      cartService.addToCart(
        CartItem(
          id: item.productId,
          nombre: item.productName,
          precio: item.price,
          quantity: item.quantity,
          image: item.productImage.isNotEmpty ? item.productImage : null,
          imagen: item.productImage.isNotEmpty ? item.productImage : null,
          commerceId: _order.commerceId,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_order.items.length} producto(s) agregados al carrito'),
      ),
    );
  }

  Future<void> _openReceipt(BuildContext context) async {
    final ok = await ReceiptPdfBuilder.shareOrderReceipt(
      _order,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _pdfSharing = loading);
      },
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al generar el PDF'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF listo para guardar o compartir'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _openRatingModal(BuildContext context) async {
    final result = await showModalBottomSheet<OrderRatingModalResult?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: OrderRatingPage(order: _order),
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    setState(() {
      _order = _order.copyWith(
        restaurantReviewCount:
            result.restaurantRated ? 1 : _order.restaurantReviewCount,
        deliveryReviewCount:
            result.deliveryRated ? 1 : _order.deliveryReviewCount,
      );
    });
  }

  String _formatOrderDateTime(DateTime d) {
    return DateFormat('d MMM y, HH:mm', 'es').format(d);
  }

  Widget _placeholderImage(
    BuildContext context,
    double w,
    double h, {
    bool circular = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: dark ? AppColors.grayDark : AppColors.grayLight,
        borderRadius: circular ? null : BorderRadius.circular(16),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        Icons.store,
        color: dark ? AppColors.white54 : AppColors.gray,
        size: w * 0.45,
      ),
    );
  }
}
