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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF23262B) : Colors.grey[200]!,
      highlightColor: isDark ? const Color(0xFF181A20) : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF23262B) : Colors.white,
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
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Ocurrió un error',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: _loadRestaurants,
            style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
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
          Icon(Icons.search_off, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
              ? 'No hay restaurantes disponibles' 
              : 'No encontramos resultados',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: Colors.white70,
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
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF23262B) : Colors.white,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          await HapticFeedback.lightImpact();
          _logger.d('🚀 Navegando a detalles de  {restaurant.nombreLocal}');
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dirección
                  if (restaurant.direccion != null)
                    Row(
                      children: [
                        Icon(Icons.location_on, color: isDark ? Colors.blueAccent : Colors.blue, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.direccion!,
                            style: GoogleFonts.manrope(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  // Estado abierto/cerrado
                  Row(
                    children: [
                      Icon(
                        restaurant.abierto == true ? Icons.check_circle : Icons.cancel,
                        color: restaurant.abierto == true ? Colors.greenAccent : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.abierto == true ? 'Abierto' : 'Cerrado',
                        style: GoogleFonts.manrope(
                          color: restaurant.abierto == true ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 14,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
        elevation: 0,
        title: Text('Restaurantes', style: GoogleFonts.manrope(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Buscar restaurante...',
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF23262B) : Colors.white,
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) {
                  _debouncer.run(() {
                    setState(() {
                      _searchQuery = value;
                    });
                  });
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Restaurant>>(
                future: _restaurantsFuture,
                builder: (context, snapshot) {
                  if (_isRefreshing) {
                    return _buildShimmerLoading();
                  } else if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error!);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  } else {
                    final filtered = _filterRestaurants(snapshot.data!);
                    if (filtered.isEmpty) return _buildEmptyState();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildRestaurantCard(filtered[index]);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}