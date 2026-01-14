import 'package:flutter/material.dart';
import '../../../models/restaurant.dart';
import '../../../features/services/restaurant_service.dart';
import 'restaurants/restaurant_details_page.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  String _sortBy = 'name';
  bool _showOnlyOpen = false;

  final List<String> _categories = [
    'Todas',
    'Pizza',
    'Hamburguesas',
    'Sushi',
    'Mexicana',
    'China',
    'Italiana',
    'Americana',
    'Vegetariana',
    'Café',
    'Postres',
  ];

  final List<String> _sortOptions = [
    'name',
    'rating',
    'distance',
    'delivery_time',
  ];

  final Map<String, String> _sortLabels = {
    'name': 'Nombre',
    'rating': 'Calificación',
    'distance': 'Distancia',
    'delivery_time': 'Tiempo de entrega',
  };

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final restaurants = await _restaurantService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredRestaurants = _restaurants.where((restaurant) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!restaurant.name.toLowerCase().contains(query) &&
            !restaurant.cuisine.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'Todas') {
        if (restaurant.cuisine != _selectedCategory) {
          return false;
        }
      }

      // Open filter
      if (_showOnlyOpen) {
        if (!restaurant.isOpen) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort restaurants
    _sortRestaurants();
  }

  void _sortRestaurants() {
    switch (_sortBy) {
      case 'name':
        _filteredRestaurants.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        _filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'distance':
        _filteredRestaurants.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'delivery_time':
        _filteredRestaurants.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _filteredRestaurants.isEmpty
                  ? _buildEmptyWidget()
                  : _buildRestaurantsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar restaurantes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRestaurants,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron restaurantes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'Todas';
                _showOnlyOpen = false;
                _applyFilters();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar Filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsList() {
    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _filteredRestaurants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailsPage.fromRestaurant(restaurant),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Restaurant Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: restaurant.image != null
                          ? Image.network(
                              restaurant.image!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.restaurant, color: Colors.grey),
                                );
                              },
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Restaurant Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (restaurant.isOpen)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Abierto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant.cuisine,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${restaurant.reviewCount} reseñas)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.deliveryTime} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.delivery_dining, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '\$${restaurant.deliveryFee.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Restaurantes'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Nombre o tipo de cocina...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _applyFilters();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtros'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Filter
              const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Sort Filter
              const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(_sortLabels[option]!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Open Only Filter
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyOpen,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyOpen = value!;
                      });
                    },
                  ),
                  const Text('Solo restaurantes abiertos'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                this.setState(() {
                  _selectedCategory = 'Todas';
                  _sortBy = 'name';
                  _showOnlyOpen = false;
                  _applyFilters();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Limpiar'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _applyFilters();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}
