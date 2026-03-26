import 'package:flutter/material.dart';
import 'package:zonix/features/services/buyer_review_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/models/order.dart';

class OrderRatingPage extends StatefulWidget {
  const OrderRatingPage({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  State<OrderRatingPage> createState() => _OrderRatingPageState();
}

class _OrderRatingPageState extends State<OrderRatingPage> {
  final _restaurantCommentController = TextEditingController();
  final _deliveryCommentController = TextEditingController();
  final _reviewService = BuyerReviewService();

  double _restaurantRating = 5;
  double _deliveryRating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _restaurantCommentController.dispose();
    _deliveryCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = AppColors.scaffoldBg(context);
    final surface = AppColors.cardBg(context);

    final hasDeliveryAgent = widget.order.deliveryAgentId != null;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Calificar pedido',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRestaurantCard(context, surface, isDark),
              const SizedBox(height: 16),
              if (hasDeliveryAgent)
                _buildDeliveryCard(context, surface, isDark),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text(
                          'Enviar calificación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Ahora no',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(
      BuildContext context, Color surface, bool isDark) {
    final commerceName =
        widget.order.commerce?['business_name']?.toString() ?? 'Restaurante';

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.grayDark : AppColors.grayLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              commerceName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText(context),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '¿Qué te pareció la comida?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText(context),
                  ),
            ),
            const SizedBox(height: 12),
            _buildStars(
              context: context,
              value: _restaurantRating,
              onChanged: (v) {
                setState(() => _restaurantRating = v);
              },
              size: 32,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restaurantCommentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Comparte tu experiencia...',
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.7)
                    : AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.grayDark
                        : AppColors.grayLight.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(
      BuildContext context, Color surface, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.grayDark : AppColors.grayLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Califica el servicio de entrega',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText(context),
                  ),
            ),
            const SizedBox(height: 12),
            _buildStars(
              context: context,
              value: _deliveryRating,
              onChanged: (v) {
                setState(() => _deliveryRating = v);
              },
              size: 28,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryCommentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '¿Cómo fue la entrega?',
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.7)
                    : AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.grayDark
                        : AppColors.grayLight.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars({
    required BuildContext context,
    required double value,
    required ValueChanged<double> onChanged,
    double size = 28,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = value >= starIndex;
        return IconButton(
          onPressed: () => onChanged(starIndex.toDouble()),
          iconSize: size,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: AppColors.ratingAmberLight,
          ),
        );
      }),
    );
  }

  Future<void> _submitRating() async {
    if (_restaurantRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una calificación para la comida')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      try {
        await _reviewService.rateRestaurant(
          orderId: widget.order.id,
          rating: _restaurantRating,
          comment: _restaurantCommentController.text.trim(),
        );
      } catch (_) {
        // Puede fallar si ya calificó (400); continuar con delivery
      }

      if (widget.order.deliveryAgentId != null && _deliveryRating > 0) {
        try {
          await _reviewService.rateDeliveryAgent(
            orderId: widget.order.id,
            rating: _deliveryRating,
            comment: _deliveryCommentController.text.trim(),
          );
        } catch (_) {
          // Puede fallar si ya calificó
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu calificación!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.red,
        ),
      );
      setState(() {
        _submitting = false;
      });
    }
  }
}

