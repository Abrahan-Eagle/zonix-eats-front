import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';
import '../../models/restaurant.dart';
import 'restaurant_details_page.dart';
import 'package:logger/logger.dart';
class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late Future<List<Restaurant>> _restaurantsFuture;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    // _restaurantsFuture = RestaurantService().fetchRestaurants();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      _logger.i('🔄 Iniciando carga de restaurantes...');
      _restaurantsFuture = RestaurantService().fetchRestaurants();
      
      // Opción 1: Loguear cuando se completa el Future
      _restaurantsFuture.then((restaurants) {
        _logger.d('✅ Datos recibidos de fetchRestaurants():');
        _logger.d('📌 Cantidad de restaurantes: ${restaurants.length}');
        
        for (var i = 0; i < restaurants.length; i++) {
          _logger.v('''
          🏷 Restaurante #${i + 1}:
          - ID: ${restaurants[i].id}
          - Nombre: ${restaurants[i].nombreLocal}
          - Dirección: ${restaurants[i].direccion ?? 'N/A'}
          - Teléfono: ${restaurants[i].telefono ?? 'N/A'}
          - Abierto: ${restaurants[i].abierto ?? 'N/A'}
          - Logo: ${restaurants[i].logoUrl ?? 'N/A'}
          - Descripción: ${restaurants[i].descripcion ?? 'N/A'}
          - Horario: ${restaurants[i].horario != null ? restaurants[i].horario.toString() : 'N/A'}
          ''');
        }
      }).catchError((error) {
        _logger.e('❌ Error al cargar restaurantes: $error');
      });
      
    } catch (e) {
      _logger.e('❌ Error en initState al cargar restaurantes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurantes')),
      body: FutureBuilder<List<Restaurant>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('Error: \\${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // _restaurantsFuture = RestaurantService().fetchRestaurants();

                        _loadRestaurants();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay restaurantes disponibles'));
          }
          final restaurants = snapshot.data!;
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(restaurant.nombreLocal),
                  subtitle: Text(restaurant.direccion ?? ''),
                  trailing: Text(restaurant.descripcion ?? ''),
                  onTap: () {

                     final logger = Logger();


                      logger.d('''
                        🚀 Navegando a RestaurantDetailsPage con:
                        - commerceId: ${restaurant.id}
                        - nombreLocal: ${restaurant.nombreLocal}
                        - direccion: ${restaurant.direccion ?? 'null'}
                        - telefono: ${restaurant.telefono ?? 'null'}
                        - abierto: ${restaurant.abierto}
                        - horario: ${restaurant.horario ?? 'null'}
                        - logoUrl: ${restaurant.logoUrl ?? 'null'}
                        - rating: null
                        - tiempoEntrega: null
                        ''');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailsPage(
                          commerceId: restaurant.id,
                          nombreLocal: restaurant.nombreLocal,
                          direccion: restaurant.direccion ?? '',
                          telefono: '', // Ajusta si tienes el campo
                          abierto: true, // Ajusta si tienes el campo
                          horario: null, // Ajusta si tienes el campo
                          logoUrl: restaurant.logoUrl,
                          rating: null, // Ajusta si tienes el campo
                          tiempoEntrega: null, // Ajusta si tienes el campo
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
