import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Full-screen dialog shown to delivery_agent when a new order is assigned.
/// Auto-rejects after [timeoutSeconds] if no action is taken.
class IncomingOrderDialog extends StatefulWidget {
  const IncomingOrderDialog({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.commerceName,
    this.deliveryAddress,
    this.deliveryFee,
    this.timeoutSeconds = 60,
  });

  final int orderId;
  final String orderNumber;
  final String? commerceName;
  final String? deliveryAddress;
  final double? deliveryFee;
  final int timeoutSeconds;

  @override
  State<IncomingOrderDialog> createState() => _IncomingOrderDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required int orderId,
    required String orderNumber,
    String? commerceName,
    String? deliveryAddress,
    double? deliveryFee,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingOrderDialog(
        orderId: orderId,
        orderNumber: orderNumber,
        commerceName: commerceName,
        deliveryAddress: deliveryAddress,
        deliveryFee: deliveryFee,
      ),
    );
  }
}

class _IncomingOrderDialogState extends State<IncomingOrderDialog>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _processing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timeoutSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        _handleReject();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_processing) return;
    setState(() => _processing = true);
    _timer?.cancel();
    try {
      final service = context.read<DeliveryService>();
      await service.acceptOrder(widget.orderId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al aceptar. Intenta de nuevo.')),
        );
        setState(() => _processing = false);
        _startTimer();
      }
    }
  }

  Future<void> _handleReject() async {
    if (_processing) return;
    setState(() => _processing = true);
    _timer?.cancel();
    try {
      final service = context.read<DeliveryService>();
      await service.rejectOrder(widget.orderId);
    } catch (_) {
      // Best-effort
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.timeoutSeconds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog.fullscreen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, child) {
                  final scale = 1.0 + _pulseController.value * 0.08;
                  return Transform.scale(scale: scale, child: child);
                },
                child: const Icon(
                  Icons.delivery_dining,
                  size: 80,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nuevo mandado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Orden ${widget.orderNumber}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (widget.commerceName != null)
                        _row(Icons.storefront, 'Comercio', widget.commerceName!),
                      if (widget.deliveryAddress != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.location_on, 'Entregar en', widget.deliveryAddress!),
                      ],
                      if (widget.deliveryFee != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.attach_money, 'Tarifa', '\$${widget.deliveryFee!.toStringAsFixed(2)}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: isDark ? AppColors.white12 : AppColors.black12,
                      valueColor: AlwaysStoppedAnimation(
                        _remaining <= 10 ? AppColors.red : AppColors.green,
                      ),
                    ),
                    Text(
                      '${_remaining}s',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _remaining <= 10 ? AppColors.red : null,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _handleReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processing ? null : _handleAccept,
                      icon: _processing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(_processing ? 'Procesando...' : 'Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryText(context)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
