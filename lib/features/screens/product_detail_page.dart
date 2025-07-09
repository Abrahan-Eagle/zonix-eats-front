// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/product.dart';
// import '../services/cart_service.dart';
// import '../../models/cart_item.dart';
// import '../services/restaurant_service.dart';
// import 'restaurant_details_page.dart';
// import 'package:logger/logger.dart';

// class ProductDetailPage extends StatefulWidget {
//   final Logger logger = Logger();
//   final Product product;
  
//   ProductDetailPage({super.key, required this.product});

//   @override
//   State<ProductDetailPage> createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   int _quantity = 1;
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     final cartService = Provider.of<CartService>(context, listen: false);
//     final double total = (widget.product.precio ?? 0) * _quantity;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detalles del producto'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             ListView(
//               padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: widget.product.imagen != null
//                       ? Image.network(
//                           widget.product.imagen!,
//                           width: double.infinity,
//                           height: 250,
//                           fit: BoxFit.cover,
//                         )
//                       : Container(
//                           width: double.infinity,
//                           height: 250,
//                           color: Colors.grey.shade200,
//                           child: const Icon(Icons.image, size: 100),
//                         ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.product.nombre,
//                             style: const TextStyle(
//                               fontSize: 22, 
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: _isLoading || widget.product.commerceId == null
//                                 ? null
//                                 : () async {
//                                     setState(() => _isLoading = true);
//                                     showDialog(
//                                       context: context,
//                                       barrierDismissible: false,
//                                       builder: (BuildContext context) {
//                                         return const Center(
//                                           child: CircularProgressIndicator(),
//                                         );
//                                       },
//                                     );

//                                     try {
//                                       final restaurantService = RestaurantService();
//                                       final restaurant = await restaurantService
//                                           .fetchRestaurantDetails2(widget.product.commerceId!);

//                                       Navigator.of(context).pop();

//                                       if (!mounted) return;

//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) => RestaurantDetailsPage(
//                                             commerceId: restaurant.id,
//                                             nombreLocal: restaurant.nombreLocal,
//                                             direccion: restaurant.direccion ?? '',
//                                             telefono: restaurant.telefono ?? '',
//                                             abierto: restaurant.abierto ?? false,
//                                             horario: restaurant.horario,
//                                             logoUrl: restaurant.logoUrl,
//                                           ),
//                                         ),
//                                       );
//                                     } catch (e, stack) {
//                                       Navigator.of(context).pop();
//                                       widget.logger.e(
//                                         'Error al obtener detalles del restaurante', 
//                                         error: e, 
//                                         stackTrace: stack,
//                                       );
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(
//                                           content: Text('Error al cargar la tienda: ${e.toString()}'),
//                                         ),
//                                       );
//                                     } finally {
//                                       if (mounted) {
//                                         setState(() => _isLoading = false);
//                                       }
//                                     }
//                                   },
//                             child: Text(
//                               widget.product.commerceId != null 
//                                   ? 'Ver la tienda' 
//                                   : 'Tienda desconocida',
//                               style: TextStyle(
//                                 color: Theme.of(context).primaryColor,
//                                 fontWeight: FontWeight.w500,
//                                 decoration: TextDecoration.underline,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'Descripción',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             widget.product.descripcion ?? 'Sin descripción',
//                             style: const TextStyle(
//                               fontSize: 16, 
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '\$${total.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 10,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Row(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade200,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.remove, color: Colors.blue),
//                             onPressed: _quantity > 1 
//                                 ? () => setState(() => _quantity--) 
//                                 : null,
//                           ),
//                           Text(
//                             '$_quantity', 
//                             style: const TextStyle(
//                               fontSize: 18, 
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.add, color: Colors.blue),
//                             onPressed: () => setState(() => _quantity++),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           cartService.addToCart(CartItem(
//                             id: widget.product.id,
//                             nombre: widget.product.nombre,
//                             precio: widget.product.precio,
//                             quantity: _quantity,
//                           ));
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Producto agregado al carrito'),
//                             ),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).primaryColor,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(13),
//                           ),
//                         ),
//                         child: const Text(
//                           'Agregar al carrito',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../services/cart_service.dart';
import '../../models/cart_item.dart';
import '../services/restaurant_service.dart';
import '../../models/restaurant.dart';
import 'restaurant_details_page.dart';
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
    final double total = (widget.product.precio ?? 0) * _quantity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del producto'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
              children: [
                _buildProductImage(),
                const SizedBox(height: 24),
                _buildProductInfo(total),
              ],
            ),
            _buildBottomControls(cartService),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: widget.product.imagen != null
          ? Image.network(
              widget.product.imagen!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, size: 100),
    );
  }

  Widget _buildProductInfo(double total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.nombre,
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRestaurantInfo(),
              const SizedBox(height: 8),
              _buildDescription(),
            ],
          ),
        ),
        _buildPrice(total),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
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
          return const Text(
            'Tienda no disponible',
            style: TextStyle(color: Colors.grey),
          );
        }

        _restaurant = snapshot.data;
        
        return GestureDetector(
          onTap: _isLoading ? null : _navigateToRestaurant,
          child: Text(
            _restaurant?.nombreLocal ?? 'Tienda desconocida',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.descripcion ?? 'Sin descripción',
          style: const TextStyle(
            fontSize: 16, 
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(double total) {
    return Text(
      '\$${total.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildBottomControls(CartService cartService) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _buildQuantitySelector(),
            const SizedBox(width: 16),
            _buildAddToCartButton(cartService),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.blue),
            onPressed: _quantity > 1 
                ? () => setState(() => _quantity--) 
                : null,
          ),
          Text(
            '$_quantity', 
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(CartService cartService) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          cartService.addToCart(CartItem(
            id: widget.product.id,
            nombre: widget.product.nombre,
            precio: widget.product.precio,
            quantity: _quantity,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto agregado al carrito'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: const Text(
          'Agregar al carrito',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}