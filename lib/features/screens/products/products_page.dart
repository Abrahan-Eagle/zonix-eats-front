import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/promotion_service.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/models/cart_item.dart';
import 'product_detail_page.dart';

const Color _primary = Color(0xFF3399FF);
const Color _accentYellow = Color(0xFFFFC107);

class ProductsPage extends StatefulWidget {
  final ProductService? productService;
  const ProductsPage({super.key, this.productService});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _productsFuture;
  late Future<List<Map<String, dynamic>>> _promosFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Popular';
  Set<String> _favProductIds = {};
  static const _favProdKey = 'favorite_products';

  static const List<({String id, String label, String emoji})> _categories = [
    (id: 'Popular', label: 'Popular', emoji: '🔥'),
    (id: 'Burgers', label: 'Burgers', emoji: '🍔'),
    (id: 'Pizza', label: 'Pizza', emoji: '🍕'),
    (id: 'Sushi', label: 'Sushi', emoji: '🍣'),
    (id: 'Otros', label: 'Otros', emoji: '🍽️'),
  ];

  Future<void> _loadProducts() async {
    setState(() {
      _productsFuture = _fetchProductsFilteredByLocation();
    });
  }

  Future<List<Product>> _fetchProductsFilteredByLocation() async {
    if (!mounted) return [];
    final productService = widget.productService ?? ProductService();
    final locationService = context.read<LocationService>();
    final radiusProvider = context.read<SearchRadiusProvider>();
    final radius = radiusProvider.effectiveRadiusKm;

    try {
      final loc = await locationService.getCurrentLocation();
      if (!mounted) return [];
      final lat = (loc['latitude'] as num).toDouble();
      final lng = (loc['longitude'] as num).toDouble();
      if (mounted) {
        final addr = loc['address'] as String?;
        if (addr != null && addr.isNotEmpty) {
          context.read<SearchRadiusProvider>().setDeliveryAddressLabel(addr);
        }
      }

      final nearbyPlaces = await locationService.getNearbyPlaces(
        latitude: lat,
        longitude: lng,
        radius: radius,
      );
      if (!mounted) return [];
      final commerceIds = nearbyPlaces.map((p) => p['id'] as int).toSet();

      final allProducts = await productService.fetchProducts();
      if (!mounted) return [];
      // Si no hay comercios cercanos, mostrar todos los productos
      if (commerceIds.isEmpty) return allProducts;
      final filtered = allProducts.where((p) => commerceIds.contains(p.commerceId)).toList();
      // Si el filtro deja la lista vacía (comercios sin coords, etc.), mostrar todos
      return filtered.isEmpty ? allProducts : filtered;
    } catch (_) {
      return productService.fetchProducts();
    }
  }

  List<Product> _filterProducts(List<Product> list, String searchQuery) {
    var out = list;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      out = out.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategory != 'Popular') {
      final cat = _selectedCategory.toLowerCase();
      out = out.where((p) {
        final c = p.category.toLowerCase();
        if (cat == 'otros') return !c.contains('burger') && !c.contains('pizza') && !c.contains('sushi');
        return c.contains(cat);
      }).toList();
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsFilteredByLocation();
    _promosFuture = PromotionService().getActivePromotions().catchError((_) => <Map<String, dynamic>>[]);
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
    _loadFavProducts();
  }

  Future<void> _loadFavProducts() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _favProductIds = (prefs.getStringList(_favProdKey) ?? []).toSet());
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
        slivers: [
          // Barra de búsqueda
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildSearchBar(isDark),
            ),
          ),
          // Chips de categorías
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((c) {
                    final sel = _selectedCategory == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        selected: sel,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Text(c.emoji), const SizedBox(width: 6), Text(c.label)],
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = c.id),
                        backgroundColor: isDark ? const Color(0xFF1A2733) : Colors.white,
                        selectedColor: _primary,
                        labelStyle: TextStyle(
                          color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Banner promocional
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _buildPromoBanner(isDark),
            ),
          ),
          // Título "Lo más pedido" / Cosmic Cravings
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lo más pedido',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F1923),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todo', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          // Grid de productos
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _loadProducts, child: const Text('Reintentar')),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final all = snapshot.data ?? [];
                final products = _filterProducts(all, _searchQuery);
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text('No hay productos', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
                  );
                }
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(context, products[index], cartService, isDark),
                    childCount: products.length,
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

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2733) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar hamburguesas, pizza...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54, size: 22),
          suffixIcon: Icon(Icons.tune, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _promosFuture,
      builder: (context, snap) {
        final promos = snap.data ?? [];
        final promo = promos.isNotEmpty ? promos.first : null;
        final title = promo?['title'] ?? 'Oferta especial';
        final desc = promo?['description'] ?? '50% en tu primer pedido';
        final imgUrl = promo?['image_url'] ?? promo?['banner_url'];
        return Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imgUrl != null && imgUrl.toString().isNotEmpty && !imgUrl.toString().contains('placeholder'))
                  Image.network(imgUrl.toString(), fit: BoxFit.cover)
                else
                  Image.asset('assets/onboarding/onboarding_eats.png', fit: BoxFit.cover),
                // Gradiente como template: from-background-dark to-transparent
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF0F1923), Colors.transparent],
                    ),
                  ),
                ),
                // Contenido igual que template: flex flex-col justify-center px-6
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _accentYellow, borderRadius: BorderRadius.circular(6)),
                        child: Text('PROMO', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Reclamar oferta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, CartService cartService, bool isDark) {
    final cardChild = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: isDark ? 6 : 8,
            offset: const Offset(0, 2),
          ),
          if (isDark)
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(imageUrl: product.image, productName: product.name, width: double.infinity, height: 100),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _toggleProductFav(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _favProductIds.contains(product.id.toString()) ? Icons.favorite : Icons.favorite_border,
                          color: _favProductIds.contains(product.id.toString()) ? Colors.redAccent : Colors.white.withValues(alpha: 0.9),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(product.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (product.category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accentYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(product.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _accentYellow)),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: _primary, size: 14),
                  const SizedBox(width: 4),
                  Text('${product.rating.toStringAsFixed(1)} (${product.reviewCount})', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                  const SizedBox(width: 8),
                  Text('${product.preparationTime} min', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${product.price.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: _accentYellow)),
                  GestureDetector(
                    onTap: () {
                      final replaced = cartService.addToCart(CartItem(id: product.id, nombre: product.name, precio: product.price, quantity: 1, image: product.image, commerceId: product.commerceId));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(replaced ? 'Carrito actualizado. Solo puedes tener productos de un comercio a la vez.' : 'Producto agregado al carrito'),
                      ));
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      child: Icon(Icons.add, color: isDark ? Colors.white : _primary, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)));
        _loadFavProducts();
      },
      child: isDark
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: cardChild,
              ),
            )
          : cardChild,
    );
  }
}
