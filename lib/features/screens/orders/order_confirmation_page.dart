import 'dart:math' show min;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.order,
  });

  final Order order;

  static const double _kMaxContentWidth = 512;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPendingPayment =
        order.status == 'pending_payment' || order.status == 'pending';
    final scaffoldBg =
        isDark ? AppColors.stitchCanvasDark : AppColors.scaffoldBgLight;
    final surfaceCard =
        isDark ? AppColors.stitchSurfaceContainer : AppColors.white;
    final onSurface = AppColors.primaryText(context);
    final onSurfaceVariant = AppColors.secondaryText(context);
    const accentGreen = AppColors.green;
    final etaShort = _shortEtaLine(order);
    final heroUrl = _heroImageUrl(order);
    final paymentLine = _paymentDisplayLine(order);
    final headline =
        isPendingPayment ? 'Pedido registrado' : '¡Pedido confirmado!';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: MediaQuery.paddingOf(context).top + 72,
                bottom: 200,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLeadCircle(
                        isPendingPayment: isPendingPayment,
                        accentGreen: accentGreen,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ORDEN #${order.orderNumber}'.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (heroUrl != null) ...[
                        LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            final h = min(w * 9 / 16, 200.0);
                            return NetworkImageWithFallback(
                              imageUrl: heroUrl,
                              width: w,
                              height: h,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                              fallbackIcon: Icons.restaurant_rounded,
                              fallbackColor: AppColors.blue.withValues(alpha: 0.5),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (isPendingPayment)
                        _buildPendingUnifiedCard(
                          context,
                          isDark: isDark,
                          surfaceCard: surfaceCard,
                          onSurface: onSurface,
                          onSurfaceVariant: onSurfaceVariant,
                        )
                      else ...[
                        _buildStatusCard(
                          context,
                          isDark: isDark,
                          surfaceCard: surfaceCard,
                          onSurface: onSurface,
                          onSurfaceVariant: onSurfaceVariant,
                          accentGreen: accentGreen,
                        ),
                        const SizedBox(height: 24),
                        _buildSummaryGrid(
                          context,
                          isDark: isDark,
                          surfaceCard: surfaceCard,
                          onSurface: onSurface,
                          onSurfaceVariant: onSurfaceVariant,
                          etaShort: etaShort,
                          paymentLine: paymentLine,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildOrderItemsSection(
                        context,
                        onSurface: onSurface,
                        onSurfaceVariant: onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGlassHeader(context, scaffoldBg: scaffoldBg),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildGlassFooter(
              context,
              scaffoldBg: scaffoldBg,
            ),
          ),
        ],
      ),
    );
  }

  /// Pendiente de pago: icono informativo (naranja). Ya pagado: éxito (verde + check).
  /// Círculo sólido, sin halo ni sombras difusas (evita aspecto “degradado”).
  Widget _buildLeadCircle({
    required bool isPendingPayment,
    required Color accentGreen,
  }) {
    final accent = isPendingPayment ? AppColors.orange : accentGreen;
    final icon = isPendingPayment
        ? Icons.receipt_long_rounded
        : Icons.check_rounded;
    final diameter = isPendingPayment ? 102.0 : 128.0;
    final iconSize = isPendingPayment ? 48.0 : 56.0;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: AppColors.white,
        size: iconSize,
      ),
    );
  }

  Widget _buildPendingUnifiedCard(
    BuildContext context, {
    required bool isDark,
    required Color surfaceCard,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.slateBorder.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa el pago',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usa el detalle del pedido para subir el comprobante y que el comercio lo valide.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.45,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _pendingInfoRow(
            Icons.upload_file_rounded,
            'Sube el comprobante desde el detalle del pedido.',
            onSurface,
            onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          _pendingInfoRow(
            Icons.schedule_rounded,
            'El tiempo de entrega (prep. + envío) aparecerá al confirmar el pago.',
            onSurface,
            onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _pendingInfoRow(
    IconData icon,
    String text,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppColors.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required bool isDark,
    required Color surfaceCard,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color accentGreen,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.slateBorder.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.room_service_rounded,
              color: AppColors.orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Tu pedido ha sido recibido!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'El restaurante ya está preparando tu comida con ingredientes frescos.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.45,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EN PREPARACIÓN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context, {
    required bool isDark,
    required Color surfaceCard,
    required Color onSurface,
    required Color onSurfaceVariant,
    required String etaShort,
    required String paymentLine,
  }) {
    final hasPaymentLabel =
        paymentLine.trim().isNotEmpty && paymentLine != '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _summaryCell(
            label: 'Tiempo estimado (prep. + envío)',
            value: etaShort,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            surfaceCard: surfaceCard,
            isDark: isDark,
            icon: Icons.schedule_rounded,
            valueFontSize: 20,
            valueFontWeight: FontWeight.w800,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCell(
            label: 'Método de pago',
            value: hasPaymentLabel ? paymentLine : 'Por confirmar',
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            surfaceCard: surfaceCard,
            isDark: isDark,
            icon: hasPaymentLabel ? Icons.credit_card_rounded : Icons.payments_rounded,
            valueFontSize: hasPaymentLabel ? 13 : 14,
            valueFontWeight: FontWeight.w700,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _summaryCell({
    required String label,
    required String value,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color surfaceCard,
    required bool isDark,
    IconData? icon,
    double valueFontSize = 20,
    FontWeight valueFontWeight = FontWeight.w800,
    int maxLines = 2,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    double borderRadius = 12,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.slateBorder.withValues(alpha: isDark ? 0.35 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 18, color: AppColors.blue),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: valueFontSize,
                    fontWeight: valueFontWeight,
                    height: 1.35,
                    color: onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(
    BuildContext context, {
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    if (order.items.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETALLES DEL PEDIDO',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              collapsedIconColor: onSurfaceVariant,
              iconColor: AppColors.blue,
              title: Text(
                'Productos (${order.items.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} ×${item.quantity}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(
    BuildContext context, {
    required Color scaffoldBg,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 20,
            right: 20,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: scaffoldBg.withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: AppColors.slateBorder.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Zonix Eats',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFooter(
    BuildContext context, {
    required Color scaffoldBg,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scaffoldBg.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: AppColors.slateBorder.withValues(alpha: 0.12),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: AppColors.white,
                          elevation: 4,
                          shadowColor: AppColors.blue.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.near_me_rounded, size: 20),
                        label: Text(
                          'SEGUIR PEDIDO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => OrderDetailPage(
                                orderId: order.id,
                                order: order,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        'Volver al inicio',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortEtaLine(Order order) {
    final m = order.estimatedDeliveryMinutes;
    if (m == null || m <= 0) {
      return 'Preparando…';
    }
    final lo = (m - 5).clamp(1, m);
    final hi = m + 5;
    if (order.isPickup) {
      return '$lo-$hi min';
    }
    return '$lo-$hi min';
  }

  String _paymentDisplayLine(Order order) {
    final raw = order.paymentMethod.trim();
    if (raw.isEmpty) return '—';
    final digits = RegExp(r'(\d{4})\s*$').firstMatch(raw);
    if (digits != null) {
      return '•••• ${digits.group(1)}';
    }
    final friendly = raw.replaceAll('_', ' ');
    if (friendly.length > 18) {
      return '${friendly.substring(0, 15)}…';
    }
    return friendly;
  }

  String? _heroImageUrl(Order order) {
    final c = order.commerce;
    if (c != null) {
      for (final k in ['image', 'logo', 'cover_image', 'photo']) {
        final v = c[k]?.toString();
        if (v != null && v.isNotEmpty) {
          return _resolveMediaUrl(v);
        }
      }
    }
    for (final i in order.items) {
      if (i.productImage.isNotEmpty) {
        return _resolveMediaUrl(i.productImage);
      }
    }
    return null;
  }

  String _resolveMediaUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = AppConfig.apiUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) return t;
    final path = t.startsWith('/') ? t : '/$t';
    return '$base$path';
  }
}
