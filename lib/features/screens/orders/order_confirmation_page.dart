import 'package:flutter/material.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = AppColors.scaffoldBg(context);
    final surfaceDark = AppColors.cardBg(context);
    final primary = AppColors.accentButton(context);
    const accentGreen = AppColors.green;
    final isPendingPayment =
        order.status == 'pending_payment' || order.status == 'pending';
    final etaRange = _arrivalEtaText(order);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                          const Spacer(),
                          Text(
                            'Zonix Eats',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Check + title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentGreen.withValues(alpha: 0.2),
                              border: Border.all(color: accentGreen, width: 4),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: accentGreen,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Pedido creado!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPendingPayment
                                ? 'Tu orden #${order.orderNumber} ha sido creada y está pendiente de pago.'
                                : 'Tu orden #${order.orderNumber} está siendo preparada',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? surfaceDark : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.grayDark
                                : AppColors.grayLight.withValues(alpha: 0.6),
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.black.withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                isPendingPayment
                                    ? 'Próximo paso'
                                    : (order.isPickup
                                        ? 'Tiempo estimado'
                                        : 'Llegada estimada'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (isPendingPayment) ...[
                                Text(
                                  'Sube tu comprobante de pago en el detalle de la orden para que el comercio la confirme.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText(context),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  etaRange,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            accentGreen.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Preparando tu comida con cuidado',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.secondaryText(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Order items
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles del pedido',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              color: AppColors.secondaryText(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: AppColors.gray.withValues(alpha: 0.2)),
                            itemBuilder: (context, index) {
                              final item = order.items[index];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.productName} x${item.quantity}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.primaryText(context),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${item.total.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText(context),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom actions (pinned)
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailPage(
                                orderId: order.id,
                                order: order,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Seguir mi pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        'Volver al inicio',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _arrivalEtaText(Order order) {
    final m = order.estimatedDeliveryMinutes;
    if (m == null || m <= 0) {
      return 'Preparando tu pedido...';
    }
    final lo = (m - 5).clamp(1, m);
    final hi = m + 5;
    if (order.isPickup) {
      return 'Listo para recoger en ~$lo-$hi min';
    }
    return 'Llegada estimada: $lo-$hi min';
  }
}

