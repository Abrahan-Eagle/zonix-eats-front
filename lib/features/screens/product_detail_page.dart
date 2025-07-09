// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/product.dart';
// import '../services/cart_service.dart';
// import '../../models/cart_item.dart';
// import '../services/restaurant_service.dart';
// import '../../models/restaurant.dart';
// import 'restaurant_details_page.dart';
// import 'package:logger/logger.dart';

// class ProductDetailPage extends StatefulWidget {
//   final logger = Logger();
//   final Product product;
//   // ProductDetailPage({Key? key, required this.product}) : super(key: key);
//   ProductDetailPage({super.key}, required this.product );

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
//                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
//                                         return const Center(child: CircularProgressIndicator());
//                                       },
//                                     );

//                                     try {
//                                       final restaurantService = RestaurantService();
//                                       final restaurant = await restaurantService.fetchRestaurantDetails2(widget.product.commerceId!);

//                                       Navigator.of(context).pop(); // Cierra el diálogo de carga

//                                       if (restaurant != null) {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (context) => RestaurantDetailsPage(
//                                               commerceId: restaurant.id,
//                                               nombreLocal: restaurant.nombreLocal,
//                                               direccion: restaurant.direccion ?? '',
//                                               telefono: restaurant.telefono ?? '',
//                                               abierto: restaurant.abierto ?? false,
//                                               horario: restaurant.horario,
//                                               logoUrl: restaurant.logoUrl,
//                                             ),
//                                           ),
//                                         );
//                                       } else {
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           const SnackBar(content: Text('No se pudo cargar la información de la tienda')),
//                                         );
//                                       }
//                                     } catch (e, stack) {
//                                       Navigator.of(context).pop();
//                                       widget.logger.e('Error al obtener detalles del restaurante', error: e, stackTrace: stack);
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(content: Text('Error al cargar la tienda: ${e.toString()}')),
//                                       );
//                                     } finally {
//                                       if (mounted) {
//                                         setState(() => _isLoading = false);
//                                       }
//                                     }
//                                   },
//                             child: Text(
//                               widget.product.commerceId != null ? 'Ver la tienda' : 'Tienda desconocida',
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
//                             textAlign: TextAlign.start,
//                             style: TextStyle(
//                               fontFamily: 'SF Pro Display',
//                               fontSize: 18,
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               height: 1.5,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             widget.product.descripcion ?? 'Sin descripción',
//                             style: const TextStyle(fontSize: 16, color: Colors.black54),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       '\$${total.toStringAsFixed(2)}',
//                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
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
//                             onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
//                           ),
//                           Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
//                             const SnackBar(content: Text('Producto agregado al carrito')),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).primaryColor,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
//                         ),
//                         child: const Text('Agregar al carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  final Logger logger = Logger();
  final Product product;
  
  ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final double total = (widget.product.precio ?? 0) * _quantity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del producto'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.product.imagen != null
                      ? Image.network(
                          widget.product.imagen!,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 100),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
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
                          GestureDetector(
                            onTap: _isLoading || widget.product.commerceId == null
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    );

                                    try {
                                      final restaurantService = RestaurantService();
                                      final restaurant = await restaurantService
                                          .fetchRestaurantDetails2(widget.product.commerceId!);

                                      Navigator.of(context).pop();

                                      if (!mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RestaurantDetailsPage(
                                            commerceId: restaurant.id,
                                            nombreLocal: restaurant.nombreLocal,
                                            direccion: restaurant.direccion ?? '',
                                            telefono: restaurant.telefono ?? '',
                                            abierto: restaurant.abierto ?? false,
                                            horario: restaurant.horario,
                                            logoUrl: restaurant.logoUrl,
                                          ),
                                        ),
                                      );
                                    } catch (e, stack) {
                                      Navigator.of(context).pop();
                                      widget.logger.e(
                                        'Error al obtener detalles del restaurante', 
                                        error: e, 
                                        stackTrace: stack,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al cargar la tienda: ${e.toString()}'),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                            child: Text(
                              widget.product.commerceId != null 
                                  ? 'Ver la tienda' 
                                  : 'Tienda desconocida',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
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
}