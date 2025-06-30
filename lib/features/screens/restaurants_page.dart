// // // import 'package:flutter/material.dart';
// // // import '../services/restaurant_service.dart';
// // // import '../../models/restaurant.dart';
// // // import 'restaurant_details_page.dart';
// // // import 'package:logger/logger.dart';
// // // class RestaurantsPage extends StatefulWidget {
// // //   const RestaurantsPage({Key? key}) : super(key: key);

// // //   @override
// // //   State<RestaurantsPage> createState() => _RestaurantsPageState();
// // // }

// // // class _RestaurantsPageState extends State<RestaurantsPage> {
// // //   late Future<List<Restaurant>> _restaurantsFuture;
// // //   final Logger _logger = Logger();

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     // _restaurantsFuture = RestaurantService().fetchRestaurants();
// // //     _loadRestaurants();
// // //   }

// // //   Future<void> _loadRestaurants() async {
// // //     try {
// // //       _logger.i('🔄 Iniciando carga de restaurantes...');
// // //       _restaurantsFuture = RestaurantService().fetchRestaurants();
      
// // //       // Opción 1: Loguear cuando se completa el Future
// // //       _restaurantsFuture.then((restaurants) {
// // //         _logger.d('✅ Datos recibidos de fetchRestaurants():');
// // //         _logger.d('📌 Cantidad de restaurantes: ${restaurants.length}');
        
// // //         for (var i = 0; i < restaurants.length; i++) {
// // //           _logger.v('''
// // //           🏷 Restaurante #${i + 1}:
// // //           - ID: ${restaurants[i].id}
// // //           - Nombre: ${restaurants[i].nombreLocal}
// // //           - Dirección: ${restaurants[i].direccion ?? 'N/A'}
// // //           - Teléfono: ${restaurants[i].telefono ?? 'N/A'}
// // //           - Abierto: ${restaurants[i].abierto ?? 'N/A'}
// // //           - Logo: ${restaurants[i].logoUrl ?? 'N/A'}
// // //           - Descripción: ${restaurants[i].descripcion ?? 'N/A'}
// // //           - Horario: ${restaurants[i].horario != null ? restaurants[i].horario.toString() : 'N/A'}
// // //           ''');
// // //         }
// // //       }).catchError((error) {
// // //         _logger.e('❌ Error al cargar restaurantes: $error');
// // //       });
      
// // //     } catch (e) {
// // //       _logger.e('❌ Error en initState al cargar restaurantes: $e');
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: const Text('Restaurantes')),
// // //       body: FutureBuilder<List<Restaurant>>(
// // //         future: _restaurantsFuture,
// // //         builder: (context, snapshot) {
// // //           if (snapshot.connectionState == ConnectionState.waiting) {
// // //             return const Center(child: CircularProgressIndicator());
// // //           } else if (snapshot.hasError) {
// // //             return Center(
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   const Icon(Icons.error, color: Colors.red, size: 48),
// // //                   const SizedBox(height: 8),
// // //                   Text('Error: \\${snapshot.error}', style: const TextStyle(color: Colors.red)),
// // //                   const SizedBox(height: 8),
// // //                   ElevatedButton(
// // //                     onPressed: () {
// // //                       setState(() {
// // //                         // _restaurantsFuture = RestaurantService().fetchRestaurants();

// // //                         _loadRestaurants();
// // //                       });
// // //                     },
// // //                     child: const Text('Reintentar'),
// // //                   ),
// // //                 ],
// // //               ),
// // //             );
// // //           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
// // //             return const Center(child: Text('No hay restaurantes disponibles'));
// // //           }
// // //           final restaurants = snapshot.data!;
// // //           return ListView.builder(
// // //             itemCount: restaurants.length,
// // //             itemBuilder: (context, index) {
// // //               final restaurant = restaurants[index];
// // //               return Card(
// // //                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //                 child: ListTile(
// // //                   title: Text(restaurant.nombreLocal),
// // //                   subtitle: Text(restaurant.direccion ?? ''),
// // //                   trailing: Text(restaurant.descripcion ?? ''),
// // //                   onTap: () {

// // //                      final logger = Logger();


// // //                       logger.d('''
// // //                         🚀 Navegando a RestaurantDetailsPage con:
// // //                         - commerceId: ${restaurant.id}
// // //                         - nombreLocal: ${restaurant.nombreLocal}
// // //                         - direccion: ${restaurant.direccion ?? 'null'}
// // //                         - telefono: ${restaurant.telefono ?? 'null'}
// // //                         - abierto: ${restaurant.abierto}
// // //                         - horario: ${restaurant.horario ?? 'null'}
// // //                         - logoUrl: ${restaurant.logoUrl ?? 'null'}
// // //                         - rating: null
// // //                         - tiempoEntrega: null
// // //                         ''');

// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                         builder: (context) => RestaurantDetailsPage(
// // //                           commerceId: restaurant.id,
// // //                           nombreLocal: restaurant.nombreLocal,
// // //                           direccion: restaurant.direccion ?? '',
// // //                           telefono: '', // Ajusta si tienes el campo
// // //                           abierto: true, // Ajusta si tienes el campo
// // //                           horario: null, // Ajusta si tienes el campo
// // //                           logoUrl: restaurant.logoUrl,
// // //                           rating: null, // Ajusta si tienes el campo
// // //                           tiempoEntrega: null, // Ajusta si tienes el campo
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               );
// // //             },
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }


// // import 'package:flutter/material.dart';
// // import '../services/restaurant_service.dart';
// // import '../../models/restaurant.dart';
// // import 'restaurant_details_page.dart';
// // import 'package:logger/logger.dart';
// // import 'package:google_fonts/google_fonts.dart';

// // class RestaurantsPage extends StatefulWidget {
// //   const RestaurantsPage({Key? key}) : super(key: key);

// //   @override
// //   State<RestaurantsPage> createState() => _RestaurantsPageState();
// // }

// // class _RestaurantsPageState extends State<RestaurantsPage> {
// //   late Future<List<Restaurant>> _restaurantsFuture;
// //   final Logger _logger = Logger();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadRestaurants();
// //   }

// //   Future<void> _loadRestaurants() async {
// //     try {
// //       _logger.i('🔄 Iniciando carga de restaurantes...');
// //       _restaurantsFuture = RestaurantService().fetchRestaurants();
      
// //       _restaurantsFuture.then((restaurants) {
// //         _logger.d('✅ Datos recibidos de fetchRestaurants():');
// //         _logger.d('📌 Cantidad de restaurantes: ${restaurants.length}');
        
// //         for (var i = 0; i < restaurants.length; i++) {
// //           _logger.v('''
// //           🏷 Restaurante #${i + 1}:
// //           - ID: ${restaurants[i].id}
// //           - Nombre: ${restaurants[i].nombreLocal}
// //           - Dirección: ${restaurants[i].direccion ?? 'N/A'}
// //           - Teléfono: ${restaurants[i].telefono ?? 'N/A'}
// //           - Abierto: ${restaurants[i].abierto ?? 'N/A'}
// //           - Logo: ${restaurants[i].logoUrl ?? 'N/A'}
// //           - Descripción: ${restaurants[i].descripcion ?? 'N/A'}
// //           - Horario: ${restaurants[i].horario != null ? restaurants[i].horario.toString() : 'N/A'}
// //           ''');
// //         }
// //       }).catchError((error) {
// //         _logger.e('❌ Error al cargar restaurantes: $error');
// //       });
      
// //     } catch (e) {
// //       _logger.e('❌ Error en initState al cargar restaurantes: $e');
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         automaticallyImplyLeading: false,
// //         title: Column(
// //           mainAxisSize: MainAxisSize.max,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               'Restaurantes Disponibles',
// //               style: GoogleFonts.outfit(
// //                 fontWeight: FontWeight.w600,
// //                 fontSize: 20,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             Row(
// //               mainAxisSize: MainAxisSize.max,
// //               children: [
// //                 Icon(
// //                   Icons.location_on,
// //                   color: Colors.grey[600],
// //                   size: 16,
// //                 ),
// //                 Text(
// //                   'Selecciona tu ubicación',
// //                   style: GoogleFonts.manrope(
// //                     fontSize: 12,
// //                     color: Colors.grey[600],
// //                   ),
// //                 ),
// //               ].divide(const SizedBox(width: 4)),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           Padding(
// //             padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.max,
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.search_rounded, size: 22),
// //                   color: Colors.black,
// //                   onPressed: () {
// //                     // Acción de búsqueda
// //                   },
// //                 ),
// //                 IconButton(
// //                   icon: const Icon(Icons.filter_list, size: 22),
// //                   color: Colors.black,
// //                   onPressed: () {
// //                     // Acción de filtro
// //                   },
// //                 ),
// //               ].divide(const SizedBox(width: 8)),
// //             ),
// //           ),
// //         ],
// //         centerTitle: false,
// //         elevation: 0,
// //       ),
// //       body: FutureBuilder<List<Restaurant>>(
// //         future: _restaurantsFuture,
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           } else if (snapshot.hasError) {
// //             return Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   const Icon(Icons.error, color: Colors.red, size: 48),
// //                   const SizedBox(height: 8),
// //                   Text('Error: ${snapshot.error}', 
// //                       style: const TextStyle(color: Colors.red)),
// //                   const SizedBox(height: 8),
// //                   ElevatedButton(
// //                     onPressed: () {
// //                       setState(() {
// //                         _loadRestaurants();
// //                       });
// //                     },
// //                     child: const Text('Reintentar'),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
// //             return Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   const Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey),
// //                   const SizedBox(height: 16),
// //                   Text('No hay restaurantes disponibles', 
// //                       style: GoogleFonts.manrope(color: Colors.grey)),
// //                 ],
// //               ),
// //             );
// //           }
          
// //           final restaurants = snapshot.data!;
// //           return Column(
// //             children: [
// //               // Filtros seleccionados (opcional)
// //               const SizedBox(height: 8),
// //               Expanded(
// //                 child: ListView(
// //                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
// //                   children: restaurants.map((restaurant) {
// //                     return Padding(
// //                       padding: const EdgeInsets.only(bottom: 12),
// //                       child: Card(
// //                         clipBehavior: Clip.antiAliasWithSaveLayer,
// //                         color: Colors.white,
// //                         elevation: 2,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(16),
// //                         ),
// //                         child: InkWell(
// //                           onTap: () {
// //                             _logger.d('''
// //                               🚀 Navegando a RestaurantDetailsPage con:
// //                               - commerceId: ${restaurant.id}
// //                               - nombreLocal: ${restaurant.nombreLocal}
// //                               - direccion: ${restaurant.direccion ?? 'null'}
// //                               - telefono: ${restaurant.telefono ?? 'null'}
// //                               - abierto: ${restaurant.abierto}
// //                               - horario: ${restaurant.horario ?? 'null'}
// //                               - logoUrl: ${restaurant.logoUrl ?? 'null'}
// //                               - rating: null
// //                               - tiempoEntrega: null
// //                             ''');

// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (context) => RestaurantDetailsPage(
// //                                   commerceId: restaurant.id,
// //                                   nombreLocal: restaurant.nombreLocal,
// //                                   direccion: restaurant.direccion ?? '',
// //                                   telefono: restaurant.telefono ?? '',
// //                                   abierto: restaurant.abierto ?? false,
// //                                   horario: restaurant.horario,
// //                                   logoUrl: restaurant.logoUrl,
// //                                   rating: null,
// //                                   tiempoEntrega: null,
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                           child: Column(
// //                             mainAxisSize: MainAxisSize.max,
// //                             children: [
// //                               // Imagen del restaurante
// //                               ClipRRect(
// //                                 borderRadius: BorderRadius.circular(12),
// //                                 child: restaurant.logoUrl != null 
// //                                   ? Image.network(
// //                                       restaurant.logoUrl!,
// //                                       width: double.infinity,
// //                                       height: 180,
// //                                       fit: BoxFit.cover,
// //                                       errorBuilder: (context, error, stackTrace) {
// //                                         return Container(
// //                                           height: 180,
// //                                           color: Colors.grey[200],
// //                                           child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
// //                                         );
// //                                       },
// //                                     )
// //                                   : Container(
// //                                       height: 180,
// //                                       color: Colors.grey[200],
// //                                       child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
// //                                     ),
// //                               ),
                              
// //                               // Información del restaurante
// //                               Padding(
// //                                 padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
// //                                 child: Column(
// //                                   crossAxisAlignment: CrossAxisAlignment.start,
// //                                   children: [
// //                                     // Nombre del restaurante
// //                                     Text(
// //                                       restaurant.nombreLocal,
// //                                       style: GoogleFonts.manrope(
// //                                         fontWeight: FontWeight.w600,
// //                                         fontSize: 16,
// //                                       ),
// //                                     ),
                                    
// //                                     const SizedBox(height: 8),
                                    
// //                                     // Fila con rating y categorías
// //                                     Row(
// //                                       children: [
// //                                         // Rating (si estuviera disponible)
// //                                         if (false) // Cambiar a true si tienes rating
// //                                         Row(
// //                                           children: [
// //                                             const Icon(
// //                                               Icons.star_rounded,
// //                                               color: Color(0xFFFFC107),
// //                                               size: 16,
// //                                             ),
// //                                             const SizedBox(width: 4),
// //                                             Text(
// //                                               '4.5',
// //                                               style: GoogleFonts.manrope(
// //                                                 fontWeight: FontWeight.w500,
// //                                                 fontSize: 14,
// //                                               ),
// //                                             ),
// //                                           ],
// //                                         ),
                                        
// //                                         // Dirección
// //                                         Expanded(
// //                                           child: Text(
// //                                             restaurant.direccion ?? 'Dirección no disponible',
// //                                             style: GoogleFonts.manrope(
// //                                               fontSize: 12,
// //                                               color: Colors.grey[600],
// //                                             ),
// //                                             maxLines: 1,
// //                                             overflow: TextOverflow.ellipsis,
// //                                           ),
// //                                         ),
// //                                       ].divide(const SizedBox(width: 8)),
// //                                     ),
                                    
// //                                     const SizedBox(height: 8),
                                    
// //                                     // Fila con tiempo de entrega y estado
// //                                     Row(
// //                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                       children: [
// //                                         // Tiempo de entrega (simulado)
// //                                         Row(
// //                                           children: [
// //                                             Icon(
// //                                               Icons.access_time_rounded,
// //                                               color: Colors.grey[600],
// //                                               size: 16,
// //                                             ),
// //                                             const SizedBox(width: 4),
// //                                             Text(
// //                                               '20-30 min',
// //                                               style: GoogleFonts.manrope(
// //                                                 fontSize: 12,
// //                                                 color: Colors.grey[600],
// //                                               ),
// //                                             ),
// //                                           ],
// //                                         ),
                                        
// //                                         // Estado (abierto/cerrado)
// //                                         Container(
// //                                           decoration: BoxDecoration(
// //                                             color: (restaurant.abierto ?? false) 
// //                                               ? Colors.green[100] 
// //                                               : Colors.red[100],
// //                                             borderRadius: BorderRadius.circular(8),
// //                                           ),
// //                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                                           child: Text(
// //                                             (restaurant.abierto ?? false) ? 'Abierto' : 'Cerrado',
// //                                             style: GoogleFonts.manrope(
// //                                               fontSize: 12,
// //                                               fontWeight: FontWeight.w500,
// //                                               color: (restaurant.abierto ?? false) 
// //                                                 ? Colors.green[800] 
// //                                                 : Colors.red[800],
// //                                             ),
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     );
// //                   }).toList(),
// //                 ),
// //               ),
// //             ],
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // Extensión para dividir widgets con SizedBox
// // extension ListWidgetExtension on List<Widget> {
// //   List<Widget> divide(Widget separator) {
// //     final result = <Widget>[];
// //     for (var i = 0; i < length; i++) {
// //       result.add(this[i]);
// //       if (i != length - 1) {
// //         result.add(separator);
// //       }
// //     }
// //     return result;
// //   }
// // }




// import 'package:flutter/material.dart';
// import '../services/restaurant_service.dart';
// import '../../models/restaurant.dart';
// import 'restaurant_details_page.dart';
// import 'package:logger/logger.dart';
// import 'package:google_fonts/google_fonts.dart';

// class RestaurantsPage extends StatefulWidget {
//   const RestaurantsPage({Key? key}) : super(key: key);

//   @override
//   State<RestaurantsPage> createState() => _RestaurantsPageState();
// }

// class _RestaurantsPageState extends State<RestaurantsPage> {
//   late Future<List<Restaurant>> _restaurantsFuture;
//   final Logger _logger = Logger();

//   @override
//   void initState() {
//     super.initState();
//     _loadRestaurants();
//   }

//   Future<void> _loadRestaurants() async {
//     try {
//       _logger.i('🔄 Iniciando carga de restaurantes...');
//       _restaurantsFuture = RestaurantService().fetchRestaurants();
      
//       _restaurantsFuture.then((restaurants) {
//         _logger.d('✅ Datos recibidos de fetchRestaurants():');
//         _logger.d('📌 Cantidad de restaurantes: ${restaurants.length}');
        
//         for (var i = 0; i < restaurants.length; i++) {
//           _logger.v('''
//           🏷 Restaurante #${i + 1}:
//           - ID: ${restaurants[i].id}
//           - Nombre: ${restaurants[i].nombreLocal}
//           - Dirección: ${restaurants[i].direccion ?? 'N/A'}
//           - Teléfono: ${restaurants[i].telefono ?? 'N/A'}
//           - Abierto: ${restaurants[i].abierto ?? 'N/A'}
//           - Logo: ${restaurants[i].logoUrl ?? 'N/A'}
//           - Descripción: ${restaurants[i].descripcion ?? 'N/A'}
//           - Horario: ${restaurants[i].horario != null ? restaurants[i].horario.toString() : 'N/A'}
//           ''');
//         }
//       }).catchError((error) {
//         _logger.e('❌ Error al cargar restaurantes: $error');
//       });
      
//     } catch (e) {
//       _logger.e('❌ Error en initState al cargar restaurantes: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//         title: Column(
//           mainAxisSize: MainAxisSize.max,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Restaurantes Disponibles',
//               style: GoogleFonts.outfit(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 20,
//                 color: Colors.black,
//               ),
//             ),
//             Row(
//               children: [
//                 Icon(
//                   Icons.location_on,
//                   color: Colors.grey[600],
//                   size: 16,
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   'Selecciona tu ubicación',
//                   style: GoogleFonts.manrope(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search_rounded, size: 22),
//             color: Colors.black,
//             onPressed: () {
//               // Acción de búsqueda
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.filter_list, size: 22),
//             color: Colors.black,
//             onPressed: () {
//               // Acción de filtro
//             },
//           ),
//           const SizedBox(width: 8),
//         ],
//         centerTitle: false,
//         elevation: 0,
//       ),
//       body: FutureBuilder<List<Restaurant>>(
//         future: _restaurantsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error, color: Colors.red, size: 48),
//                   const SizedBox(height: 8),
//                   Text('Error: ${snapshot.error}', 
//                       style: const TextStyle(color: Colors.red)),
//                   const SizedBox(height: 8),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         _loadRestaurants();
//                       });
//                     },
//                     child: const Text('Reintentar'),
//                   ),
//                 ],
//               ),
//             );
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey),
//                   const SizedBox(height: 16),
//                   Text('No hay restaurantes disponibles', 
//                       style: GoogleFonts.manrope(color: Colors.grey)),
//                 ],
//               ),
//             );
//           }
          
//           final restaurants = snapshot.data!;
//           return ListView(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             children: restaurants.map((restaurant) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Card(
//                   clipBehavior: Clip.antiAliasWithSaveLayer,
//                   color: Colors.white,
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: InkWell(
//                     onTap: () {
//                       _logger.d('''
//                         🚀 Navegando a RestaurantDetailsPage con:
//                         - commerceId: ${restaurant.id}
//                         - nombreLocal: ${restaurant.nombreLocal}
//                         - direccion: ${restaurant.direccion ?? 'null'}
//                         - telefono: ${restaurant.telefono ?? 'null'}
//                         - abierto: ${restaurant.abierto}
//                         - horario: ${restaurant.horario ?? 'null'}
//                         - logoUrl: ${restaurant.logoUrl ?? 'null'}
//                         - rating: null
//                         - tiempoEntrega: null
//                       ''');

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => RestaurantDetailsPage(
//                             commerceId: restaurant.id,
//                             nombreLocal: restaurant.nombreLocal,
//                             direccion: restaurant.direccion ?? '',
//                             telefono: restaurant.telefono ?? '',
//                             abierto: restaurant.abierto ?? false,
//                             horario: restaurant.horario,
//                             logoUrl: restaurant.logoUrl,
//                             rating: null,
//                             tiempoEntrega: null,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         // Imagen del restaurante
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: restaurant.logoUrl != null 
//                             ? Image.network(
//                                 restaurant.logoUrl!,
//                                 width: double.infinity,
//                                 height: 180,
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     height: 180,
//                                     color: Colors.grey[200],
//                                     child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
//                                   );
//                                 },
//                               )
//                             : Container(
//                                 height: 180,
//                                 color: Colors.grey[200],
//                                 child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
//                               ),
//                         ),
                        
//                         // Información del restaurante
//                         Padding(
//                           padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Nombre del restaurante
//                               Text(
//                                 restaurant.nombreLocal,
//                                 style: GoogleFonts.manrope(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
                              
//                               const SizedBox(height: 8),
                              
//                               // Fila con rating y categorías
//                               Row(
//                                 children: [
//                                   // Dirección
//                                   Expanded(
//                                     child: Text(
//                                       restaurant.direccion ?? 'Dirección no disponible',
//                                       style: GoogleFonts.manrope(
//                                         fontSize: 12,
//                                         color: Colors.grey[600],
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                 ],
//                               ),
                              
//                               const SizedBox(height: 8),
                              
//                               // Fila con tiempo de entrega y estado
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   // Tiempo de entrega (simulado)
//                                   Row(
//                                     children: [
//                                       Icon(
//                                         Icons.access_time_rounded,
//                                         color: Colors.grey[600],
//                                         size: 16,
//                                       ),
//                                       const SizedBox(width: 4),
//                                       Text(
//                                         '20-30 min',
//                                         style: GoogleFonts.manrope(
//                                           fontSize: 12,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
                                  
//                                   // Estado (abierto/cerrado)
//                                   Container(
//                                     decoration: BoxDecoration(
//                                       color: (restaurant.abierto ?? false) 
//                                         ? Colors.green[100] 
//                                         : Colors.red[100],
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                     child: Text(
//                                       (restaurant.abierto ?? false) ? 'Abierto' : 'Cerrado',
//                                       style: GoogleFonts.manrope(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w500,
//                                         color: (restaurant.abierto ?? false) 
//                                           ? Colors.green[800] 
//                                           : Colors.red[800],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }


import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import '../services/restaurant_service.dart';
import '../../models/restaurant.dart';
import 'restaurant_details_page.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late Future<List<Restaurant>> _restaurantsFuture;
  final Logger _logger = Logger();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isRefreshing = false;
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer._timer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _logger.d('🔄 Llegamos al final de la lista');
      // Aquí podrías cargar más datos si implementas paginación
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      _logger.i('🔄 Iniciando carga de restaurantes...');
      setState(() => _isRefreshing = true);
      _restaurantsFuture = RestaurantService().fetchRestaurants();
      
      _restaurantsFuture.then((restaurants) {
        _logger.d('✅ Datos recibidos de fetchRestaurants()');
        _logger.d('📌 Cantidad de restaurantes: ${restaurants.length}');
      }).catchError((error) {
        _logger.e('❌ Error al cargar restaurantes: $error');
      }).whenComplete(() => setState(() => _isRefreshing = false));
      
    } catch (e) {
      _logger.e('❌ Error en initState al cargar restaurantes: $e');
      setState(() => _isRefreshing = false);
    }
  }

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants) {
    if (_searchQuery.isEmpty) return restaurants;
    return restaurants.where((restaurant) => 
      restaurant.nombreLocal.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (restaurant.direccion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Ocurrió un error',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(),
            ),
          ),
          FilledButton(
            onPressed: _loadRestaurants,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
              ? 'No hay restaurantes disponibles' 
              : 'No encontramos resultados',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          await HapticFeedback.lightImpact();
          _logger.d('🚀 Navegando a detalles de ${restaurant.nombreLocal}');
          
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
                rating: null,
                tiempoEntrega: null,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del restaurante
            AspectRatio(
              aspectRatio: 16/9,
              child: restaurant.logoUrl != null 
                ? Image.network(
                    restaurant.logoUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                            : null,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                  ),
            ),

            // Información del restaurante
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    restaurant.nombreLocal,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Dirección
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.direccion ?? 'Dirección no disponible',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Estado y tiempo de entrega
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tiempo estimado
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '20-30 min',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      // Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (restaurant.abierto ?? false)
                            ? Colors.green[100]
                            : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (restaurant.abierto ?? false) ? 'Abierto' : 'Cerrado',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: (restaurant.abierto ?? false)
                              ? Colors.green[800]
                              : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadRestaurants,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              title: Text(
                'Restaurantes',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              floating: true,
              snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  color: Colors.black,
                  onPressed: () {
                    // Opcional: Focus en el campo de búsqueda
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar restaurantes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      _debouncer.run(() {
                        setState(() => _searchQuery = value.trim());
                      });
                    },
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: FutureBuilder<List<Restaurant>>(
                future: _restaurantsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                    return SliverToBoxAdapter(child: _buildShimmerLoading());
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(child: _buildErrorWidget(snapshot.error!));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState());
                  }

                  final filteredRestaurants = _filterRestaurants(snapshot.data!);
                  
                  if (filteredRestaurants.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState());
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRestaurantCard(filteredRestaurants[index]),
                      ),
                      childCount: filteredRestaurants.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}