import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late Future<List<dynamic>> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = RestaurantService().fetchRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurantes')),
      body: FutureBuilder<List<dynamic>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                  title: Text(restaurant['nombre'] ?? 'Sin nombre'),
                  subtitle: Text(restaurant['direccion'] ?? ''),
                  trailing: Text(restaurant['telefono'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
