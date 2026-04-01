import 'dart:ui';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/commerce_product_service.dart';
import 'package:zonix/features/utils/gps_dialog_helper.dart';
import 'package:zonix/features/services/promotion_service.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';
import 'package:zonix/features/utils/safe_parse.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';
import 'package:zonix/features/utils/debouncer.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/widgets/app_skeleton.dart';
import 'package:zonix/models/cart_item.dart';
import 'product_detail_page.dart';

const Color _primary = AppColors.blue;
const Color _accentYellow = AppColors.amber;

class ProductsPage extends StatefulWidget {
  final ProductService? productService;
  const ProductsPage({super.key, this.productService});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Map<String, dynamic>>> _promosFuture;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  Set<String> _favProductIds = {};
  final Debouncer _debouncer = Debouncer(milliseconds: 400);
  static const _favProdKey = 'favorite_products';

  /// Stale-while-revalidate: keeps cached products to avoid skeleton flash
  /// when the background refresh reassigns [_productsFuture].
  final List<Product> _products = [];
  List<Product>? _cachedProducts;
  Set<int>? _nearbyCommerceIds;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _perPage = 16;

  static const _nearbyIdsKey = 'nearby_commerce_ids';
  static const _nearbyIdsTsKey = 'nearby_commerce_ids_ts';

  List<String> _categories = const ['Todos'];

  /// Phase 1: return cached products instantly.
  /// Phase 2: refresh from network in background and update UI.
  Future<void> _initProducts() async {
    final cached = await ProductService.getCachedProducts();
    if (cached != null && cached.isNotEmpty) {
      _cachedProducts = cached;
      final filtered = await _applyCachedNearbyFilter(cached);
      _products
        ..clear()
        ..addAll(filtered);
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _currentPage = 1;
          _hasMore = true;
        });
      }
      _refreshProductsInBackground();
      return;
    }
    await _loadProductsPage(reset: true);
  }

  /// Filters products using cached nearby commerce IDs (avoids HTTP call on
  /// the critical path when cache is available).
  Future<List<Product>> _applyCachedNearbyFilter(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_nearbyIdsTsKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age < 15 * 60 * 1000) {
        final idStrings = prefs.getStringList(_nearbyIdsKey);
        if (idStrings != null && idStrings.isNotEmpty) {
          final ids = idStrings
              .map((s) => int.tryParse(s))
              .whereType<int>()
              .toSet();
          final filtered =
              products.where((p) => ids.contains(p.commerceId)).toList();
          return filtered.isEmpty ? products : filtered;
        }
      }
    } catch (_) {}
    return products;
  }

  void _refreshProductsInBackground() {
    _loadProductsPage(reset: true, silent: true).then((_) {
      final fresh = _products;
      if (mounted && fresh.isNotEmpty) {
        _cachedProducts = List<Product>.from(fresh);
      }
    }).catchError((e) {
      if (e is LocationDisabledException && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación desactivada — mostrando todos los productos'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _ensureNearbyCommerceIds() async {
    if (_nearbyCommerceIds != null) return;
    final locationService = context.read<LocationService>();
    final radiusProvider = context.read<SearchRadiusProvider>();
    final radius = radiusProvider.effectiveRadiusKm;

    try {
      final loc = await locationService.getCurrentLocation();
      if (!mounted) return;
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
      if (!mounted) return;
      final commerceIds = nearbyPlaces.map((p) => safeInt(p['id'])).toSet();
      _nearbyCommerceIds = commerceIds;

      // Persist nearby IDs for stale-while-revalidate on next visit
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList(
            _nearbyIdsKey, commerceIds.map((e) => e.toString()).toList());
        prefs.setInt(_nearbyIdsTsKey, DateTime.now().millisecondsSinceEpoch);
      });

    } on LocationDisabledException {
      if (mounted) showGpsDisabledDialog(context);
      _nearbyCommerceIds = <int>{};
    } catch (_) {
      _nearbyCommerceIds = <int>{};
      final fallback = await _applyCachedNearbyFilter(_cachedProducts ?? []);
      if (fallback.isNotEmpty && mounted && _products.isEmpty) {
        setState(() {
          _products
            ..clear()
            ..addAll(fallback);
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadProductsPage({bool reset = false, bool silent = false}) async {
    if (_isLoadingMore) return;
    if (!reset && !_hasMore) return;
    final nextPage = reset ? 1 : _currentPage + 1;
    final productService = widget.productService ?? ProductService();

    setState(() {
      if (!silent && reset) {
        _isInitialLoading = _products.isEmpty;
      }
      _isLoadingMore = true;
    });

    try {
      await _ensureNearbyCommerceIds();
      final search = _searchQuery.trim();
      final pageResult = search.isNotEmpty
          ? await productService.fetchSearchProductsPage(
              page: nextPage,
              perPage: _perPage,
              search: search,
            )
          : await productService.fetchProductsPage(
              page: nextPage,
              perPage: _perPage,
            );

      var pageProducts = pageResult.products;
      if (search.isEmpty) {
        final nearbyIds = _nearbyCommerceIds;
        if (nearbyIds != null && nearbyIds.isNotEmpty) {
          final filtered = pageProducts.where((p) => nearbyIds.contains(p.commerceId)).toList();
          pageProducts = filtered.isEmpty && nextPage == 1 ? pageResult.products : filtered;
        }
      }

      if (!mounted) return;
      setState(() {
        if (reset) {
          _products
            ..clear()
            ..addAll(pageProducts);
        } else {
          _products.addAll(pageProducts);
        }
        _currentPage = pageResult.currentPage;
        _hasMore = pageResult.hasMore;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_products.isEmpty && _cachedProducts != null) {
        setState(() {
          _products
            ..clear()
            ..addAll(_cachedProducts!);
          _isInitialLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  List<Product> _filterProducts(List<Product> list, String searchQuery) {
    var out = list;
    // Cuando hay búsqueda server-side activa, evitamos doble filtrado local.
    if (_selectedCategory != 'Todos') {
      final cat = _selectedCategory.toLowerCase();
      out = out.where((p) {
        final c = p.category.toLowerCase();
        return c.contains(cat);
      }).toList();
    }
    return out;
  }

  Future<void> _loadDynamicCategories() async {
    try {
      final categories = await CommerceProductService.getProductCategories();
      final labels = categories
          .map((c) => (c['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
      if (!mounted || labels.isEmpty) return;
      setState(() {
        _categories = ['Todos', ...labels.toSet()];
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'Todos';
        }
      });
    } catch (_) {
      // fallback: mantener categorías por defecto
    }
  }

  @override
  void initState() {
    super.initState();
    _initProducts();
    _loadDynamicCategories();
    _promosFuture = Future.delayed(
      const Duration(seconds: 3),
      () => PromotionService().getActivePromotions(),
    ).catchError((_) => <Map<String, dynamic>>[]);
    _searchController.addListener(() {
      _debouncer.run(() {
        if (!mounted) return;
        final nextQuery = _searchController.text;
        if (_searchQuery == nextQuery) return;
        setState(() => _searchQuery = nextQuery);
        _loadProductsPage(reset: true);
      });
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadProductsPage();
      }
    });
    _loadFavProducts();
  }

  Future<void> _loadFavProducts() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _favProductIds = (prefs.getStringList(_favProdKey) ?? []).toSet());
    }
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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          controller: _scrollController,
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
                      final sel = _selectedCategory == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          selected: sel,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c)
                            ],
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = c),
                          backgroundColor:
                              isDark ? AppColors.grayDark : AppColors.white,
                          selectedColor: _primary,
                          labelStyle: TextStyle(
                            color: sel
                                ? AppColors.white
                                : (isDark ? AppColors.white70 : AppColors.black87),
                            fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
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
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            // Grid de productos
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: _isInitialLoading
                  ? SliverFillRemaining(
                      child: AppSkeleton.list(count: 5, useCards: true))
                  : Builder(
                      builder: (context) {
                        final products = _filterProducts(_products, _searchQuery);
                        if (products.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                                child: Text('No hay productos',
                                    style: TextStyle(
                                        color: isDark
                                            ? AppColors.white54
                                            : AppColors.black54))),
                          );
                        }
                        return SliverMainAxisGroup(
                          slivers: [
                            SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildProductCard(
                                    context, products[index], cartService, isDark),
                                childCount: products.length,
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
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
        color: isDark ? AppColors.grayDark : AppColors.grayLight,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? AppColors.white12 : AppColors.grayLight),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar hamburguesas, pizza...',
          hintStyle: TextStyle(color: isDark ? AppColors.white38 : AppColors.black45),
          prefixIcon: Icon(Icons.search,
              color: isDark ? AppColors.white54 : AppColors.black54, size: 22),
          suffixIcon: Icon(Icons.tune,
              color: isDark ? AppColors.white54 : AppColors.black54, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black87, fontSize: 15),
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
            boxShadow: const [
              BoxShadow(
                  color: AppColors.black26, blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imgUrl != null &&
                    imgUrl.toString().isNotEmpty &&
                    !imgUrl.toString().contains('placeholder'))
                  Image.network(
                    imgUrl.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                        'assets/onboarding/onboarding_eats.png',
                        fit: BoxFit.cover),
                  )
                else
                  Image.asset('assets/onboarding/onboarding_eats.png',
                      fit: BoxFit.cover),
                // Gradiente como template: from-background-dark to-transparent
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.backgroundDark, AppColors.transparent],
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _accentYellow,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('PROMO',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black87)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white.withValues(alpha: 0.85)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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

  Widget _buildProductCard(BuildContext context, Product product,
      CartService cartService, bool isDark) {
    final cardChild = Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.grayDark.withValues(alpha: 0.5)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.1)
                : AppColors.grayLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: isDark ? 6 : 8,
            offset: const Offset(0, 2),
          ),
          if (isDark)
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                  child: ProductImage(
                      imageUrl: product.image,
                      productName: product.name,
                      width: double.infinity,
                      height: 100),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _toggleProductFav(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _favProductIds.contains(product.id.toString())
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favProductIds.contains(product.id.toString())
                            ? AppColors.red
                            : AppColors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(product.name,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (product.category.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(product.category,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _accentYellow)),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: _primary, size: 14),
                const SizedBox(width: 4),
                Text(
                    '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.white54 : AppColors.black54)),
                const SizedBox(width: 8),
                Text('•',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.white38 : AppColors.black38)),
                const SizedBox(width: 8),
                Text('${product.preparationTime} min',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.white54 : AppColors.black54)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _accentYellow)),
                GestureDetector(
                  onTap: () {
                    if (!product.isAvailable ||
                        (product.hasStockLimit && product.stock <= 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Producto no disponible o sin stock'),
                      ));
                      return;
                    }
                    final result = cartService.addToCart(CartItem(
                        id: product.id,
                        nombre: product.name,
                        precio: product.price,
                        quantity: 1,
                        image: product.image,
                        stock: product.hasStockLimit ? product.stock : null,
                        category: product.category,
                        commerceId: product.commerceId));
                    final message = switch (result.status) {
                      CartAddStatus.replacedCommerce =>
                        'Carrito actualizado. Solo puedes tener productos de un comercio a la vez.',
                      CartAddStatus.blockedLimit =>
                        'No puedes agregar mas de 100 unidades',
                      CartAddStatus.blockedStock =>
                        'Cantidad no disponible por stock',
                      _ => 'Producto agregado al carrito',
                    };
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.1)
                          : AppColors.grayLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              isDark ? AppColors.white24 : AppColors.borderLight),
                    ),
                    child: Icon(Icons.add,
                        color: isDark ? AppColors.white : _primary, size: 18),
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
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: product)));
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
