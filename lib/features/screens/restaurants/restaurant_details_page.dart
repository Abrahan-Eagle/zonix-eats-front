import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/promotion_service.dart';
import 'package:zonix/features/services/buyer_review_service.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/models/restaurant.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';
import 'package:zonix/features/screens/products/product_detail_page.dart';
import 'package:zonix/config/app_config.dart';
import 'package:latlong2/latlong.dart';
import 'package:zonix/widgets/osm_map_widget.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final int commerceId;
  final String nombreLocal;
  final String direccion;
  final String telefono;
  final bool abierto;
  final Map<String, dynamic>? horario;
  final String? logoUrl;
  final double? rating;
  final String? tiempoEntrega;
  final String? banco;
  final String? cedula;
  final String? businessType;
  final double? latitude;
  final double? longitude;

  RestaurantDetailsPage({
    super.key,
    Restaurant? restaurant,
    int? commerceId,
    String? nombreLocal,
    String? direccion,
    String? telefono,
    bool? abierto,
    double? latitude,
    double? longitude,
    this.horario,
    this.logoUrl,
    this.rating,
    this.tiempoEntrega,
    this.banco,
    this.cedula,
    this.businessType,
  })  : commerceId = restaurant?.id ?? commerceId ?? 0,
        nombreLocal = restaurant?.nombreLocal ?? nombreLocal ?? '',
        direccion = restaurant?.direccion ?? direccion ?? '',
        telefono = restaurant?.telefono ?? telefono ?? '',
        abierto = restaurant?.abierto ?? abierto ?? false,
        latitude = restaurant?.latitude ?? latitude,
        longitude = restaurant?.longitude ?? longitude;

  factory RestaurantDetailsPage.fromRestaurant(Restaurant restaurant) {
    return RestaurantDetailsPage(restaurant: restaurant);
  }

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  late Future<List<Product>> _productsFuture;
  late Future<List<Map<String, dynamic>>> _promotionsFuture;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  bool _isFavorite = false;
  int _totalReviews = 0;
  double _averageRating = 0.0;
  String _selectedCategory = 'Todos';
  List<String> _categories = ['Todos'];
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  static const Color _accent = Color(0xFFFFC107);
  static const Color _primary = Color(0xFF3399FF);
  static const Color _bgLight = Color(0xFFF5F7F8);
  static const Color _bgDark = Color(0xFF0F1923);

  static final Map<int, double> _scrollOffsets = {};
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _scrollOffsets[widget.commerceId] ?? 0.0,
    );
    _scrollController.addListener(() {
      _scrollOffsets[widget.commerceId] = _scrollController.offset;
    });
    _productsFuture = _loadProducts();
    _promotionsFuture =
        PromotionService().getActivePromotions(commerceId: widget.commerceId);
    _reviewsFuture =
        BuyerReviewService().getRestaurantReviews(widget.commerceId);
    _loadFavorite();
    _loadReviewStats();
  }

  Future<List<Product>> _loadProducts() async {
    final allProducts = await ProductService().fetchProducts();
    final commerceProducts =
        allProducts.where((p) => p.commerceId == widget.commerceId).toList();
    final categories = commerceProducts
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (mounted) {
      setState(() {
        _categories = ['Todos', ...categories];
      });
    }
    return commerceProducts;
  }

  static const _favKey = 'favorite_restaurants';
  static const _favProdKey = 'favorite_products';
  Set<String> _favProductIds = {};

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favKey) ?? [];
    final prodIds = prefs.getStringList(_favProdKey) ?? [];
    _isFavorite = ids.contains(widget.commerceId.toString());
    _favProductIds = prodIds.toSet();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    await HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favKey) ?? [];
    final idStr = widget.commerceId.toString();
    if (ids.contains(idStr)) {
      ids.remove(idStr);
      _isFavorite = false;
    } else {
      ids.add(idStr);
      _isFavorite = true;
    }
    await prefs.setStringList(_favKey, ids);
    if (mounted) setState(() {});
  }

  Future<void> _toggleProductFav(int productId) async {
    await HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favProdKey) ?? [];
    final idStr = productId.toString();
    if (ids.contains(idStr)) {
      ids.remove(idStr);
      _favProductIds.remove(idStr);
    } else {
      ids.add(idStr);
      _favProductIds.add(idStr);
    }
    await prefs.setStringList(_favProdKey, ids);
    if (mounted) setState(() {});
  }

  Widget _productFavBtn(int productId, Color fallbackColor) {
    final isFav = _favProductIds.contains(productId.toString());
    return GestureDetector(
      onTap: () => _toggleProductFav(productId),
      child: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        size: 18,
        color: isFav ? Colors.redAccent : fallbackColor,
      ),
    );
  }

  Future<void> _loadReviewStats() async {
    final reviews =
        await BuyerReviewService().getRestaurantReviews(widget.commerceId);
    _totalReviews = reviews.length;
    if (_totalReviews > 0) {
      _averageRating = reviews
              .map((r) => (r['rating'] ?? 0.0) as num)
              .reduce((a, b) => a + b) /
          _totalReviews;
    } else {
      _averageRating = 0.0;
    }
    setState(() {});
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  String _getTodaySchedule(Map<String, dynamic> horario) {
    final days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    final diasES = {
      'monday': 'Lun', 'tuesday': 'Mar', 'wednesday': 'Mié',
      'thursday': 'Jue', 'friday': 'Vie', 'saturday': 'Sáb', 'sunday': 'Dom',
    };
    final today = days[DateTime.now().weekday - 1];
    if (horario.containsKey(today)) {
      final value = horario[today].toString().replaceAll(RegExp(r'[{}]'), '');
      return '${diasES[today]}: $value';
    }
    return 'Horario no disponible';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: _buildCartBar(isDark),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── 1. HEADER: imagen + degradado + botones flotantes ──
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? _bgDark : Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.logoUrl != null && widget.logoUrl!.isNotEmpty)
                    Image.network(
                      widget.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: isDark ? _bgDark : const Color(0xFF111827)),
                    )
                  else
                    Container(color: isDark ? _bgDark : const Color(0xFF111827)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _floatingBtn(Icons.arrow_back, () => Navigator.of(context).pop(), isDark),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                            child: _showSearch
                                ? Container(
                                    key: const ValueKey('search-bar'),
                                    width: MediaQuery.of(context).size.width * 0.65,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar...',
                                        hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14),
                                        prefixIcon: Icon(Icons.search, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(() {
                                            _showSearch = false;
                                            _searchController.clear();
                                            _searchQuery = '';
                                          }),
                                          child: Icon(Icons.close, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      onChanged: (v) => setState(() => _searchQuery = v),
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('action-buttons'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _floatingBtn(Icons.search, () => setState(() => _showSearch = true), isDark),
                                      const SizedBox(width: 8),
                                      _floatingBtn(
                                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                                        _toggleFavorite,
                                        isDark,
                                        iconColor: _isFavorite ? Colors.redAccent : null,
                                      ),
                                      const SizedBox(width: 8),
                                      _floatingBtn(Icons.share, _shareRestaurant, isDark),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. INFO DEL RESTAURANTE ──
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badge abierto/cerrado + info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nombreLocal,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.abierto
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.abierto ? 'ABIERTO' : 'CERRADO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: widget.abierto ? Colors.green : Colors.red,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showInfoModal(theme, isDark, cardColor, textPrimary, textSecondary, borderColor),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info_outline, size: 20, color: _primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rating + tiempo + tipo de negocio
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_totalReviews > 0) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Aún no hay reseñas para este restaurante'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: _accent, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _averageRating.toStringAsFixed(1),
                                style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _totalReviews > 0 ? '($_totalReviews)' : '(Sin reseñas)',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (widget.tiempoEntrega != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 18, color: textSecondary),
                              const SizedBox(width: 4),
                              Text(widget.tiempoEntrega!, style: TextStyle(fontSize: 14, color: textSecondary)),
                            ],
                          ),
                        if (widget.businessType != null && widget.businessType!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _formatBusinessType(widget.businessType!),
                                style: TextStyle(fontSize: 14, color: textSecondary),
                              ),
                            ],
                          )
                        else if (widget.direccion.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.direccion.replaceAll('\n', ' ').split(',').first,
                                  style: TextStyle(fontSize: 14, color: textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Horario del día
                    if (widget.horario != null && widget.horario!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 16, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _getTodaySchedule(widget.horario!),
                            style: TextStyle(fontSize: 13, color: textSecondary),
                          ),
                        ],
                      ),
                    ],

                    // WhatsApp clickeable
                    if (widget.telefono.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openWhatsApp(widget.telefono),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                              SizedBox(width: 6),
                              Text(
                                'Escribir por WhatsApp',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF25D366)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Botón GPS para ver ubicación (siempre visible)
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _openLocationInMaps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 18, color: _primary),
                            SizedBox(width: 6),
                            Text(
                              'Ver ubicación',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 14, color: _primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. PROMO BANNER ──
          SliverToBoxAdapter(child: _buildPromoBanner(isDark)),

          // ── 4. CHIPS DE CATEGORÍA ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final sel = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : cardColor,
                          borderRadius: BorderRadius.circular(999),
                          border: sel ? null : Border.all(color: borderColor),
                          boxShadow: sel
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color: sel
                                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 5. PRODUCTOS ──
          SliverToBoxAdapter(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerList(cardColor, borderColor);
                } else if (snapshot.hasError) {
                  return _emptyState(Icons.error_outline, 'Error al cargar productos', textSecondary);
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyState(Icons.shopping_bag_outlined, 'No hay productos disponibles', textSecondary);
                }

                final filtered = _filterProducts(snapshot.data!);
                if (filtered.isEmpty) {
                  return _emptyState(Icons.search_off, 'No se encontraron productos', textSecondary);
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          'Lo más vendido',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ),
                      ...filtered.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final product = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 250 + (index * 40).clamp(0, 200)),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 12),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildProductCard(product, cardColor, textPrimary, textSecondary, borderColor),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── 7. RESEÑAS ──
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                final reviews = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reseñas recientes', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      ...reviews.take(2).map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: _primary, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['customer_name'] ?? 'Cliente',
                                          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13)),
                                      Text(r['comment'] ?? '',
                                          style: TextStyle(color: textSecondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.star, color: _accent, size: 16),
                                const SizedBox(width: 2),
                                Text('${r['rating'] ?? ''}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                              ],
                            ),
                          )),
                      if (reviews.length > 2)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () {}, child: const Text('Ver todas')),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  WIDGETS AUXILIARES
  // ══════════════════════════════════════════════════════════════

  Widget _dot(Color c) => Container(width: 4, height: 4, decoration: BoxDecoration(color: c.withValues(alpha: 0.5), shape: BoxShape.circle));

  String _formatBusinessType(String raw) {
    final parts = raw.split(RegExp(r'[,;_]')).map((s) {
      final t = s.trim().replaceAll('_', ' ');
      return t.isEmpty ? '' : '${t[0].toUpperCase()}${t.length > 1 ? t.substring(1).toLowerCase() : ''}';
    }).where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? raw : parts.join(' • ');
  }

  Widget _floatingBtn(IconData icon, VoidCallback onTap, bool isDark, {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        child: Icon(icon, size: 22, color: iconColor ?? (isDark ? Colors.white : const Color(0xFF0F172A))),
      ),
    );
  }

  String get _baseShareUrl => AppConfig.apiUrl;

  // ── COMPARTIR RESTAURANTE ──
  void _shareRestaurant() {
    final link = '$_baseShareUrl/restaurant/${widget.commerceId}';
    final text = '🍽️ *${widget.nombreLocal}* en Zonix Eats!\n'
        '${widget.direccion.isNotEmpty ? '📍 ${widget.direccion}\n' : ''}'
        '${widget.telefono.isNotEmpty ? '📞 ${widget.telefono}\n' : ''}'
        '${widget.abierto ? '✅ Abierto ahora' : '⛔ Cerrado'}\n'
        '\n👉 $link';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ── COMPARTIR PRODUCTO ──
  void _shareProduct(Product product) {
    final link = '$_baseShareUrl/product/${product.id}';
    final text = '🛒 *${product.name}* - \$${product.price.toStringAsFixed(2)}\n'
        '${product.description.isNotEmpty ? '${product.description}\n' : ''}'
        '🍽️ En *${widget.nombreLocal}* - Zonix Eats\n'
        '\n👉 $link';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ── WHATSAPP CON MENSAJE PREDISEÑADO ──
  Future<void> _openWhatsApp(String phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono inválido')),
      );
      return;
    }
    final msg = Uri.encodeComponent(
      'Hola ${widget.nombreLocal}, los contacto desde Zonix Eats. '
      'Me gustaría hacer una consulta sobre su menú.',
    );
    final uri = Uri.parse('https://wa.me/$normalized?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  String? _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('58')) return digits;
    if (digits.length == 11 && digits.startsWith('0')) return '58${digits.substring(1)}';
    if (digits.length == 10 && (digits.startsWith('4') || digits.startsWith('2'))) return '58$digits';
    return digits;
  }

  // ── ABRIR UBICACIÓN EN GOOGLE MAPS ──
  Future<void> _openLocationInMaps() async {
    Uri url;
    if (widget.latitude != null && widget.longitude != null) {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}&travelmode=driving',
      );
    } else {
      final addr = Uri.encodeComponent('${widget.nombreLocal} ${widget.direccion}');
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$addr');
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa')),
      );
    }
  }

  // ── MODAL DE INFO (horario + teléfono) ──
  void _showInfoModal(ThemeData theme, bool isDark, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor) {
    final diasES = {
      'monday': 'Lunes', 'tuesday': 'Martes', 'wednesday': 'Miércoles',
      'thursday': 'Jueves', 'friday': 'Viernes', 'saturday': 'Sábado', 'sunday': 'Domingo',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(widget.nombreLocal, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.abierto ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.abierto ? 'ABIERTO' : 'CERRADO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.abierto ? Colors.green : Colors.red),
                ),
              ),
              if (widget.direccion.isNotEmpty) ...[
                const SizedBox(height: 16),
                _infoRow(Icons.location_on, widget.direccion.replaceAll('\n', ', '), textPrimary, textSecondary),
              ],
              if (widget.telefono.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openWhatsApp(widget.telefono),
                  child: _infoRow(Icons.chat, 'Escribir por WhatsApp', const Color(0xFF25D366), textSecondary, underline: true),
                ),
              ],

              // Mini mapa + GPS
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.latitude != null && widget.longitude != null
                    ? OsmMapWidget(
                        center: LatLng(widget.latitude!, widget.longitude!),
                        zoom: 15,
                        height: 140,
                        markers: [
                          MapMarker.create(
                            point: LatLng(widget.latitude!, widget.longitude!),
                            color: _primary,
                            size: 28,
                          ),
                        ],
                      )
                    : Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 32, color: _primary.withValues(alpha: 0.4)),
                              const SizedBox(height: 6),
                              Text('Toca "Cómo llegar" para ver la ubicación', style: TextStyle(fontSize: 12, color: _primary.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _openLocationInMaps();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions, size: 18, color: _primary),
                      SizedBox(width: 8),
                      Text('Cómo llegar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                      Spacer(),
                      Icon(Icons.open_in_new, size: 16, color: _primary),
                    ],
                  ),
                ),
              ),

              // Horario completo
              if (widget.horario != null && widget.horario!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Horario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 8),
                ...widget.horario!.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(diasES[e.key] ?? e.key, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13)),
                      ),
                      Expanded(child: Text(e.value.toString().replaceAll(RegExp(r'[{}]'), ''), style: TextStyle(color: textSecondary, fontSize: 13))),
                    ],
                  ),
                )),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color textColor, Color secondaryColor, {bool underline = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: secondaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(
            fontSize: 14,
            color: textColor,
            decoration: underline ? TextDecoration.underline : null,
          )),
        ),
      ],
    );
  }

  // ── PROMO BANNER ──
  Widget _buildPromoBanner(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final promos = snapshot.data!;
        final promo = promos.first;
        return GestureDetector(
          onTap: () => _showPromoDetail(promos, isDark),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROMO ACTIVA · ${promos.length}', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      )),
                      const SizedBox(height: 2),
                      Text(
                        promo['title'] ?? promo['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: _accent.withValues(alpha: 0.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPromoDetail(List<Map<String, dynamic>> promos, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Promociones activas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 16),
              ...promos.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_offer, color: _accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title'] ?? 'Promoción', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14)),
                          if (p['description'] != null && p['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(p['description'].toString(), style: TextStyle(color: textSecondary, fontSize: 13)),
                          ],
                          if (p['discount_percentage'] != null) ...[
                            const SizedBox(height: 4),
                            Text('${p['discount_percentage']}% de descuento', style: const TextStyle(fontWeight: FontWeight.w600, color: _accent, fontSize: 13)),
                          ],
                          if (p['end_date'] != null) ...[
                            const SizedBox(height: 4),
                            Text('Válida hasta: ${p['end_date']}', style: TextStyle(color: textSecondary, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── SHIMMER SKELETON LOADING ──
  Widget _buildShimmerList(Color cardColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (i) => _shimmerCard(cardColor, borderColor)),
      ),
    );
  }

  Widget _shimmerCard(Color cardColor, Color borderColor) {
    final shimmerBase = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 14, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(width: 200, height: 10, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(width: 160, height: 10, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 14),
                Container(width: 60, height: 14, decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 112, height: 112,
            decoration: BoxDecoration(color: shimmerBase, borderRadius: BorderRadius.circular(14)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg, Color c) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: c),
            const SizedBox(height: 16),
            Text(msg, style: TextStyle(color: c)),
          ],
        ),
      ),
    );
  }

  // ── BARRA INFERIOR "VER CARRITO" ──
  Widget _buildCartBar(bool isDark) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        final int total = cartService.items.fold(0, (s, i) => s + i.quantity);
        final double amount = cartService.items.fold<double>(0, (s, i) => s + ((i.precio ?? 0) * i.quantity));
        if (total == 0) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: _primary.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text('$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      const Text('Ver Carrito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
                    Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── TARJETA DE PRODUCTO CON +/- ──
  Widget _buildProductCard(Product product, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor) {
    return Consumer<CartService>(
      builder: (context, cartService, _) {
        final qty = cartService.items.where((i) => i.id == product.id).fold(0, (s, i) => s + i.quantity);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showProductDetails(product),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          _productFavBtn(product.id, textSecondary),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _shareProduct(product),
                            child: Icon(Icons.share, size: 16, color: textSecondary),
                          ),
                        ],
                      ),
                      if (product.category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(product.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _accent)),
                        ),
                      ],
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(product.description, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: _accent, fontSize: 16)),
                          const Spacer(),
                          // Selector +/-
                          if (qty > 0) ...[
                            _qtyBtn(Icons.remove, () {
                              final item = cartService.items.firstWhere((i) => i.id == product.id);
                              cartService.decrementQuantity(item);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('$qty', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
                            ),
                          ],
                          _qtyBtn(Icons.add, () {
                            cartService.addToCart(CartItem(
                              id: product.id,
                              nombre: product.name,
                              precio: product.price,
                              quantity: 1,
                              imagen: product.image,
                              commerceId: product.commerceId,
                            ));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: product.image.isNotEmpty
                        ? Image.network(product.image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: textSecondary.withValues(alpha: 0.1), child: Icon(Icons.fastfood, size: 40, color: textSecondary)))
                        : Container(color: textSecondary.withValues(alpha: 0.1), child: Icon(Icons.fastfood, size: 40, color: textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: _primary),
      ),
    );
  }

  void _showProductDetails(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );
    if (!context.mounted) return;
    _loadFavorite();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
