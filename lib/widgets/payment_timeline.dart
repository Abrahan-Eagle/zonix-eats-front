import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Visual timeline of the manual payment flow for the buyer.
///
/// Steps: Pedido creado -> Comercio confirma -> Comprobante subido -> Comercio valida -> Pagado.
/// The [currentStep] is derived from the order status and payment fields.
class PaymentTimeline extends StatefulWidget {
  const PaymentTimeline({
    super.key,
    required this.currentStep,
    this.createdAt,
    this.compact = false,
  });

  /// 0 = order created, 1 = commerce approved, 2 = proof uploaded,
  /// 3 = commerce validating, 4 = paid/completed.
  final int currentStep;
  final DateTime? createdAt;
  final bool compact;

  /// Derives the step from order fields.
  static int stepFromOrder({
    required String status,
    required bool approvedForPayment,
    required bool hasPaymentProof,
    required bool isPaymentValidated,
  }) {
    if (status == 'cancelled') return -1;
    if (isPaymentValidated ||
        status == 'paid' ||
        status == 'processing' ||
        status == 'preparing' ||
        status == 'shipped' ||
        status == 'out_for_delivery' ||
        status == 'delivered') {
      return 4;
    }
    if (hasPaymentProof) return 3;
    if (approvedForPayment) return 2;
    if (status == 'pending_payment' || status == 'pending') return 1;
    return 0;
  }

  @override
  State<PaymentTimeline> createState() => _PaymentTimelineState();
}

class _PaymentTimelineState extends State<PaymentTimeline> {
  Timer? _ticker;
  String _elapsed = '';

  static const _steps = [
    _StepData(Icons.receipt_long, 'Pedido creado'),
    _StepData(Icons.storefront, 'Comercio confirma'),
    _StepData(Icons.upload_file, 'Comprobante subido'),
    _StepData(Icons.search, 'Comercio valida'),
    _StepData(Icons.check_circle, 'Pagado'),
  ];

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    if (widget.currentStep >= 0 && widget.currentStep < 4) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _updateElapsed());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    if (widget.createdAt == null) return;
    final diff = DateTime.now().difference(widget.createdAt!);
    if (diff.inMinutes < 1) {
      _elapsed = 'Hace un momento';
    } else if (diff.inMinutes < 60) {
      _elapsed = 'Hace ${diff.inMinutes} min';
    } else {
      _elapsed = 'Hace ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentStep < 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.grayDark : AppColors.white;
    final borderColor = isDark ? AppColors.white12 : AppColors.black12;
    final textPrimary = AppColors.primaryText(context);
    final textSecondary = AppColors.secondaryText(context);

    return Container(
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 20, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                'Estado del pago',
                style: TextStyle(
                  fontSize: widget.compact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (_elapsed.isNotEmpty)
                Text(_elapsed, style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ),
          SizedBox(height: widget.compact ? 12 : 16),
          ...List.generate(_steps.length, (i) {
            final step = _steps[i];
            final done = i < widget.currentStep;
            final active = i == widget.currentStep;
            final pending = i > widget.currentStep;

            Color circleColor;
            Color iconColor;
            Color lineColor;
            if (done) {
              circleColor = AppColors.green;
              iconColor = AppColors.white;
              lineColor = AppColors.green;
            } else if (active) {
              circleColor = AppColors.blue;
              iconColor = AppColors.white;
              lineColor = AppColors.blue.withValues(alpha: 0.3);
            } else {
              circleColor = isDark ? AppColors.white12 : AppColors.black12;
              iconColor = textSecondary;
              lineColor = isDark ? AppColors.white12 : AppColors.black12;
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CircleIcon(
                      icon: step.icon,
                      color: circleColor,
                      iconColor: iconColor,
                      size: widget.compact ? 28 : 32,
                      active: active,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.label,
                        style: TextStyle(
                          fontSize: widget.compact ? 13 : 14,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: pending ? textSecondary : textPrimary,
                        ),
                      ),
                    ),
                    if (done)
                      const Icon(Icons.check, size: 16, color: AppColors.green),
                    if (active)
                      const _PulsingDot(color: AppColors.blue),
                  ],
                ),
                if (i < _steps.length - 1)
                  Padding(
                    padding: EdgeInsets.only(left: widget.compact ? 13 : 15),
                    child: Container(
                      width: 2,
                      height: widget.compact ? 16 : 20,
                      color: lineColor,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.size,
    this.active = false,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
            : null,
      ),
      child: Icon(icon, size: size * 0.5, color: iconColor),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
