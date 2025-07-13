import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zonix/features/services/restaurant_service.dart';
import 'package:zonix/models/restaurant.dart';
import 'restaurant_details_page.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/models/product.dart';
import '../../services/test_auth_service.dart';
import 'package:zonix/features/utils/debouncer.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';

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
  Future<List<Restaurant>>? _restaurantsFuture;
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
      
      // Primero probar la autenticación
      _logger.i('🔍 Probando autenticación...');
      final authResult = await TestAuthService.testAuth();
      
      if (authResult.containsKey('error')) {
        _logger.e('❌ Error de autenticación: $authResult');
        setState(() => _isRefreshing = false);
        return;
      }
      
      _logger.i('✅ Autenticación exitosa, cargando restaurantes...');
      
      setState(() {
        _restaurantsFuture = RestaurantService().fetchRestaurants();
      });
      
      _restaurantsFuture?.then((restaurants) {
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
              child: RestaurantImage(
                imageUrl: restaurant.logoUrl ?? '',
                restaurantName: restaurant.nombreLocal,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
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
              sliver: _restaurantsFuture == null
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: _buildShimmerLoading(),
                    ),
                  )
                : FutureBuilder<List<Restaurant>>(
                    future: _restaurantsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                        return SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _buildShimmerLoading(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildErrorWidget(snapshot.error!),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        );
                      }

                      final filteredRestaurants = _filterRestaurants(snapshot.data!);
                      
                      if (filteredRestaurants.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        );
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