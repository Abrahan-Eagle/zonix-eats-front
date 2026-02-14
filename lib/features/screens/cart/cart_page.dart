import 'package:flutter/material.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/cart/checkout_page.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;
    final total = cartItems.fold<double>(0, (sum, item) => sum + (item.precio ?? 0) * item.quantity);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    width: double.infinity,
                    child: Text(
                      'Carrito', // TODO: internacionalizar
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(1, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, right: 24),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.secondaryText(context).withOpacity(0.2)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.notifications_none, size: 24, color: AppColors.secondaryText(context).withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(child: Text('El carrito está vacío', style: TextStyle(color: AppColors.secondaryText(context), fontSize: 18))) // TODO: internacionalizar
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: Card(
                              color: AppColors.cardBg(context),
                              shadowColor: AppColors.orange.withOpacity(0.10),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        color: AppColors.grayLight,
                                        width: 80,
                                        height: 80,
                                        child: Icon(Icons.shopping_bag, size: 40, color: AppColors.secondaryText(context).withOpacity(0.2)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nombre,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryText(context),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Cantidad: ${item.quantity}', // TODO: internacionalizar
                                            style: TextStyle(fontSize: 15, color: AppColors.secondaryText(context)),
                                          ),
                                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              item.notes!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.secondaryText(context).withOpacity(0.9),
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 5),
                                          Text(
                                            '\u20a1${item.precio?.toStringAsFixed(2) ?? '-'}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.success(context),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  cartService.decrementQuantity(item);
                                                },
                                                borderRadius: BorderRadius.circular(15),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.grayDark,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.remove_sharp, size: 18, color: AppColors.white.withOpacity(0.7)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${item.quantity}',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText(context)),
                                              ),
                                              const SizedBox(width: 12),
                                              InkWell(
                                                onTap: () {
                                                  cartService.removeFromCart(item);
                                                  cartService.addToCart(CartItem(
                                                    id: item.id,
                                                    nombre: item.nombre,
                                                    precio: item.precio,
                                                    quantity: item.quantity + 1,
                                                    imagen: item.imagen,
                                                    image: item.image,
                                                    notes: item.notes,
                                                  ));
                                                },
                                                borderRadius: BorderRadius.circular(15),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accentButton(context),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.add, color: AppColors.white, size: 18),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: AppColors.error(context)),
                                                onPressed: () {
                                                  cartService.removeFromCart(item);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Producto eliminado del carrito')), // TODO: internacionalizar
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (cartItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
                  child: Text(
                    'Resumen de orden', // TODO: internacionalizar
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.primaryText(context)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Items:', // TODO: internacionalizar
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.secondaryText(context)),
                            ),
                          ),
                          Text(
                            '${cartItems.length}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.primaryText(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 0.1, thickness: 1, color: AppColors.secondaryText(context).withOpacity(0.1)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total a pagar:', // TODO: internacionalizar
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText(context)),
                            ),
                          ),
                          Text(
                            '\u20a1${total.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.success(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: cartItems.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 13, 24, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CheckoutPage()),
                      );
                    },
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text('Proceder al pago', style: TextStyle(color: Colors.white, fontSize: 18)), // TODO: internacionalizar
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
