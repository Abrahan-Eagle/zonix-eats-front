import 'dart:async';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/restaurant_service.dart';
import 'package:zonix/models/restaurant.dart';
import 'restaurant_details_page.dart';
import 'package:zonix/features/utils/debouncer.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';

/// Colores del template Stitch Zonix Eats - Restaurantes
class _TemplateColors {
  static const Color primary = AppColors.blue;
  static const Color bgDark = AppColors.backgroundDark;
  static const Color cardDark = AppColors.grayDark;
  static const Color ratingYellow = AppColors.amber;
}

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  Future<List<Restaurant>>? _restaurantsFuture;
  final Logger _logger = Logger();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isRefreshing = false;
  String _selectedCategory = 'Todos';
  List<String> _businessCategories = ['Todos'];
  Set<String> _favoriteIds = {};
  final _debouncer = Debouncer(milliseconds: 500);

  static const _favKey = 'favorite_restaurants';

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = RestaurantService().fetchRestaurants().then((list) {
      _extractCategories(list);
      return list;
    });
    _scrollController.addListener(_onScroll);
    _loadFavorites();
  }

  void _extractCategories(List<Restaurant> restaurants) {
    final types = restaurants
        .map((r) => (r.businessType ?? '').trim())
        .where((t) => t.isNotEmpty)
        .map(_capitalizeCategory)
        .toSet()
        .toList()
      ..sort();
    if (mounted) {
      setState(() => _businessCategories = ['Todos', ...types]);
    }
  }

  String _capitalizeCategory(String raw) {
    final cleaned = raw.replaceAll('_', ' ').trim().toLowerCase();
    if (cleaned.isEmpty) return raw;
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favKey) ?? [];
    if (mounted) setState(() => _favoriteIds = ids.toSet());
  }

  Future<void> _toggleFavorite(int commerceId) async {
    await HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favKey) ?? [];
    final idStr = commerceId.toString();
    if (ids.contains(idStr)) {
      ids.remove(idStr);
    } else {
      ids.add(idStr);
    }
    await prefs.setStringList(_favKey, ids);
    if (mounted) setState(() => _favoriteIds = ids.toSet());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _logger.d('🔄 Llegamos al final de la lista');
    }
  }

  Future<void> _loadRestaurants() async {
    _logger.i('🔄 Cargando restaurantes...');
    setState(() => _isRefreshing = true);
    setState(() {
      _restaurantsFuture = RestaurantService().fetchRestaurants().then((list) {
        _extractCategories(list);
        return list;
      });
    });
    _restaurantsFuture!
        .then((r) => _logger.d('✅ ${r.length} restaurantes'))
        .catchError((e) => _logger.e('❌ $e'))
        .whenComplete(() => setState(() => _isRefreshing = false));
    await _loadFavorites();
  }

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants) {
    return restaurants.where((r) {
      final matchSearch = _searchQuery.isEmpty ||
          r.nombreLocal.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.direccion.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r.businessType ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchCategory = _selectedCategory == 'Todos' ||
          _capitalizeCategory(r.businessType ?? '') == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? _TemplateColors.cardDark : AppColors.gray,
      highlightColor: isDark ? _TemplateColors.bgDark : AppColors.gray,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: isDark ? _TemplateColors.cardDark : AppColors.white,
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.red),
          const SizedBox(height: 16),
          Text(
            'Ocurrió un error',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppColors.white70),
            ),
          ),
          FilledButton(
            onPressed: _loadRestaurants,
            style: FilledButton.styleFrom(
                backgroundColor: _TemplateColors.primary),
            child:
                const Text('Reintentar', style: TextStyle(color: AppColors.white)),
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
          const Icon(Icons.search_off, size: 48, color: AppColors.gray),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay restaurantes disponibles'
                : 'No encontramos resultados',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, color: AppColors.white70),
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
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white24),
              ),
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rating = restaurant.rating;
    final deliveryTime = restaurant.deliveryTime;
    final deliveryFee = restaurant.deliveryFee;
    final showPromoBadge =
        index == 0; // Template: primera tarjeta con badge Promoción

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark
            ? _TemplateColors.cardDark.withValues(alpha: 0.6)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.white12 : AppColors.grayLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await HapticFeedback.lightImpact();
          if (!mounted) {
            return;
          }
          _logger.d('🚀 Navegando a detalles de ${restaurant.nombreLocal}');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsPage(
                commerceId: restaurant.id,
                nombreLocal: restaurant.nombreLocal,
                direccion: restaurant.direccion,
                telefono: restaurant.telefono,
                abierto: restaurant.abierto,
                horario: restaurant.horario,
                logoUrl: restaurant.logoUrl,
                rating: null,
                tiempoEntrega: null,
                banco: restaurant.pagoMovilBanco,
                cedula: restaurant.pagoMovilCedula,
                businessType: restaurant.businessType,
                latitude: restaurant.latitude,
                longitude: restaurant.longitude,
              ),
            ),
          );
          if (!mounted) {
            return;
          }
          _loadFavorites();
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen h-44 (176px)
            SizedBox(
              height: 176,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: RestaurantImage(
                      imageUrl: restaurant.logoUrl,
                      restaurantName: restaurant.nombreLocal,
                      width: double.infinity,
                      height: 176,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  // Icono favoritos (top right) - funcional
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(restaurant.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.black54 : AppColors.white)
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _favoriteIds.contains(restaurant.id.toString())
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: _favoriteIds.contains(restaurant.id.toString())
                              ? AppColors.red
                              : AppColors.gray,
                        ),
                      ),
                    ),
                  ),
                  // Badge Promoción (bottom left)
                  if (showPromoBadge)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _TemplateColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PROMOCIÓN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info del restaurante
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.nombreLocal,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _TemplateColors.ratingYellow
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: _TemplateColors.ratingYellow),
                            const SizedBox(width: 2),
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : 'Nuevo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _TemplateColors.ratingYellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Tipo de cocina
                  Text(
                    restaurant.cuisineDisplay,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppColors.white60 : AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tiempo + Costo envío
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: _TemplateColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$deliveryTime-${deliveryTime + 10} min',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.white70 : AppColors.gray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.delivery_dining,
                          size: 16, color: _TemplateColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        deliveryFee > 0
                            ? 'Envío \$${deliveryFee.toStringAsFixed(2)}'
                            : 'Envío Gratis',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.white70 : AppColors.gray,
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
      backgroundColor: isDark ? _TemplateColors.bgDark : AppColors.grayLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar (misma separación que ProductsPage)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.plusJakartaSans(
                  color: isDark ? AppColors.white : AppColors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar comida o restaurantes',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.gray),
                filled: true,
                fillColor: isDark ? _TemplateColors.cardDark : AppColors.white,
                prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onChanged: (value) {
                _debouncer.run(() {
                  setState(() => _searchQuery = value);
                });
              },
            ),
          ),
          // Categorías de establecimientos
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _businessCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _businessCategories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _TemplateColors.primary
                            : (isDark
                                ? _TemplateColors.cardDark
                                : AppColors.white),
                        border: selected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppColors.white24
                                    : AppColors.borderLight),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 0) ...[
                            Icon(Icons.restaurant_menu,
                                size: 14,
                                color: selected
                                    ? AppColors.white
                                    : (isDark
                                        ? AppColors.white70
                                        : AppColors.gray)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected
                                  ? AppColors.white
                                  : (isDark ? AppColors.white70 : AppColors.gray),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Título + Lista
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              'Restaurantes destacados',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Restaurant>>(
              future: _restaurantsFuture,
              builder: (context, snapshot) {
                if (_isRefreshing ||
                    snapshot.connectionState == ConnectionState.waiting) {
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(filtered[index], index);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
