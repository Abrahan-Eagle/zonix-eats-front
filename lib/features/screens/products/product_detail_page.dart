import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/models/restaurant.dart';
import 'package:zonix/features/services/restaurant_service.dart';
import 'package:zonix/features/screens/restaurants/restaurant_details_page.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';
import 'package:logger/logger.dart';
import 'package:zonix/features/utils/app_colors.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Logger logger = Logger();
  int _quantity = 1;
  bool _isLoading = false;
  late Future<Restaurant?> _restaurantFuture;
  Restaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _restaurantFuture = _loadRestaurant();
  }

  Future<Restaurant?> _loadRestaurant() async {
    if (widget.product.commerceId == null) return null;
    
    try {
      final restaurantService = RestaurantService();
      return await restaurantService.fetchRestaurantDetails2(widget.product.commerceId!);
    } catch (e, stack) {
      logger.e('Error loading restaurant', error: e, stackTrace: stack);
      return null;
    }
  }

  void _navigateToRestaurant() async {
    if (_restaurant == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailsPage(
            commerceId: _restaurant!.id,
            nombreLocal: _restaurant!.nombreLocal,
            direccion: _restaurant!.direccion ?? '',
            telefono: _restaurant!.telefono ?? '',
            abierto: _restaurant!.abierto ?? false,
            horario: _restaurant!.horario,
            logoUrl: _restaurant!.logoUrl,
          ),
        ),
      );
    } catch (e) {
      logger.e('Navigation error', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final double total = (widget.product.price) * _quantity;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
                AppColors.headerGradientEnd(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Detalles del producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: IconThemeData(color: AppColors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
              children: [
                Card(
                  color: AppColors.cardBg(context),
                  shadowColor: AppColors.orange.withOpacity(0.10),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: _buildProductImage(),
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppColors.cardBg(context),
                  shadowColor: AppColors.orange.withOpacity(0.10),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildProductInfo(total, context),
                  ),
                ),
              ],
            ),
            _buildBottomControls(cartService, context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ProductImage(
      imageUrl: widget.product.image,
      productName: widget.product.name,
      width: double.infinity,
      height: 250,
      borderRadius: BorderRadius.circular(16),
    );
  }



  Widget _buildProductInfo(double total, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildRestaurantInfo(context),
              const SizedBox(height: 8),
              _buildDescription(context),
            ],
          ),
        ),
        _buildPrice(total, context),
      ],
    );
  }

  Widget _buildRestaurantInfo(BuildContext context) {
    return FutureBuilder<Restaurant?>(
      future: _restaurantFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Text(
            'Tienda no disponible', // TODO: internacionalizar
            style: TextStyle(color: AppColors.secondaryText(context)),
          );
        }

        _restaurant = snapshot.data;
        
        return GestureDetector(
          onTap: _isLoading ? null : _navigateToRestaurant,
          child: Text(
            _restaurant?.nombreLocal ?? 'Tienda desconocida', // TODO: internacionalizar
            style: TextStyle(
              color: AppColors.accentButton(context),
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción', // TODO: internacionalizar
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.description ?? 'Sin descripción', // TODO: internacionalizar
          style: TextStyle(
            fontSize: 16, 
            color: AppColors.secondaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(double total, BuildContext context) {
    return Text(
      '\$${total.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.success(context),
      ),
    );
  }

  Widget _buildBottomControls(CartService cartService, BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _buildQuantitySelector(context),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  cartService.addToCart(CartItem(
                    id: widget.product.id,
                    nombre: widget.product.name,
                    precio: widget.product.price,
                    quantity: _quantity,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto añadido al carrito')), // TODO: internacionalizar
                  );
                },
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text('Añadir al carrito', style: TextStyle(color: Colors.white, fontSize: 18)), // TODO: internacionalizar
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: AppColors.primaryText(context)),
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          ),
          Text('$_quantity', style: TextStyle(fontSize: 18, color: AppColors.primaryText(context))),
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primaryText(context)),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(CartService cartService, BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentButton(context),
          foregroundColor: AppColors.primaryText(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: () {
          cartService.addToCart(CartItem(
            id: widget.product.id,
            nombre: widget.product.name,
            precio: widget.product.price,
            quantity: _quantity,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto agregado al carrito')),
          );
        },
        child: Text(
          'Agregar al carrito',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText(context),
          ),
        ),
      ),
    );
  }
}