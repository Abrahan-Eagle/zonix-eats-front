import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/cart/checkout_page.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';
import 'package:zonix/models/cart_item.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;
    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + (item.precio ?? 0) * item.quantity);
    const deliveryFee = 2.50;
    final total = subtotal + deliveryFee;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: cartItems.isEmpty
                    ? _buildEmptyState(context)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        children: [
                          _buildMiCarritoHeader(context, totalItems),
                          const SizedBox(height: 16),
                          ...cartItems.map((item) => _buildCartItem(context, cartService, item)),
                          const SizedBox(height: 100),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: cartItems.isNotEmpty
            ? _buildFooterSummaryAndCheckout(context, subtotal: subtotal, deliveryFee: deliveryFee, total: total)
            : null,
      ),
    );
  }

  Widget _buildMiCarritoHeader(BuildContext context, int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mi Carrito',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppColors.primaryText(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentButton(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$totalItems ${totalItems == 1 ? 'Item' : 'Items'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accentButton(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.secondaryText(context).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'El carrito está vacío',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora restaurantes y agrega productos',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartService cartService, CartItem item) {
    final imageUrl = item.image ?? item.imagen ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 96,
              height: 96,
              child: imageUrl.isNotEmpty
                  ? NetworkImageWithFallback(
                      imageUrl: imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      fallbackIcon: Icons.restaurant,
                    )
                  : Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.grayLight,
                      child: Icon(Icons.restaurant, size: 40, color: AppColors.secondaryText(context).withValues(alpha: 0.3)),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        cartService.removeFromCart(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto eliminado del carrito')),
                        );
                      },
                      icon: Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.error(context)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${(item.precio ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentButton(context),
                      ),
                    ),
                    _buildQuantityStepper(context, cartService, item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartService cartService, CartItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => cartService.decrementQuantity(item),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.transparent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.remove_rounded,
                size: 18,
                color: isDark ? AppColors.secondaryText(context) : AppColors.accentButton(context),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => cartService.incrementQuantity(item),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.accentButton(context).withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.accentButton(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSummaryAndCheckout(
    BuildContext context, {
    required double subtotal,
    required double deliveryFee,
    required double total,
  }) {
    final isFreeDelivery = deliveryFee <= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppColors.secondaryText(context).withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tarifa de envío',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  Text(
                    isFreeDelivery ? 'Gratis' : '\$${deliveryFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isFreeDelivery ? AppColors.success(context) : AppColors.primaryText(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.secondaryText(context).withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckoutPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ir a pagar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
