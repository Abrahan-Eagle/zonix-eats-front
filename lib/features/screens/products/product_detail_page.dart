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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
      appBar: AppBar(
        title: const Text('Detalles del producto'),
        backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF23262B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildProductImage(),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF23262B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildProductInfo(total, isDark),
                ),
              ],
            ),
            _buildBottomControls(cartService, isDark),
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



  Widget _buildProductInfo(double total, bool isDark) {
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
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              _buildRestaurantInfo(isDark),
              const SizedBox(height: 8),
              _buildDescription(isDark),
            ],
          ),
        ),
        _buildPrice(total, isDark),
      ],
    );
  }

  Widget _buildRestaurantInfo(bool isDark) {
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
            'Tienda no disponible',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          );
        }

        _restaurant = snapshot.data;
        
        return GestureDetector(
          onTap: _isLoading ? null : _navigateToRestaurant,
          child: Text(
            _restaurant?.nombreLocal ?? 'Tienda desconocida',
            style: TextStyle(
              color: isDark ? Colors.blueAccent : Colors.blue,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescription(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.description ?? 'Sin descripción',
          style: TextStyle(
            fontSize: 16, 
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(double total, bool isDark) {
    return Text(
      '\$${total.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.greenAccent,
      ),
    );
  }

  Widget _buildBottomControls(CartService cartService, bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _buildQuantitySelector(isDark),
            const SizedBox(width: 16),
            _buildAddToCartButton(cartService, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23262B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: isDark ? Colors.blueAccent : Colors.blue),
            onPressed: _quantity > 1 
                ? () => setState(() => _quantity--) 
                : null,
          ),
          Text(
            '$_quantity', 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: isDark ? Colors.blueAccent : Colors.blue),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(CartService cartService, bool isDark) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
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
            const SnackBar(content: Text('Producto agregado al carrito')),
          );
        },
        child: Text(
          'Agregar al carrito',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}