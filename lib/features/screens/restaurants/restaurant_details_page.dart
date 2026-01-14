/// Vista de detalles de un restaurante/comercio.
/// 
/// Muestra la información principal del restaurante, su logo, estado (abierto/cerrado),
/// rating, tiempo de entrega, dirección, teléfono y horario. Permite buscar y filtrar productos
/// por categoría, ver detalles de cada producto y agregarlos al carrito.
/// 
/// Estructura principal:
/// - SliverAppBar: Header con logo, nombre, estado, rating, tiempo de entrega y datos básicos.
/// - Barra de búsqueda: Permite buscar productos por nombre o descripción.
/// - Filtros de categoría: Chips horizontales para filtrar productos por categoría.
/// - Listado de productos: Cards con imagen, nombre, descripción, precio y botón para agregar al carrito.
/// - Modal de detalles: Al tocar un producto, muestra detalles ampliados y botón para agregar al carrito.
/// - Botón flotante: Acceso rápido al carrito.
/// 
/// Notas de personalización:
/// - Para subir/bajar el logo, ajusta el valor de `margin` en el Container del logo.
/// - Para cambiar colores, modifica los valores en el método build según el modo claro/oscuro.
/// - Para agregar más datos del restaurante, amplía los parámetros del widget y el header.
///
///

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/promotion_service.dart';
import 'package:zonix/features/services/buyer_review_service.dart';
import 'package:zonix/features/services/favorites_service.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/models/restaurant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';

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

  RestaurantDetailsPage({
    Key? key,
    Restaurant? restaurant,
    int? commerceId,
    String? nombreLocal,
    String? direccion,
    String? telefono,
    bool? abierto,
    this.horario,
    this.logoUrl,
    this.rating,
    this.tiempoEntrega,
    this.banco,
    this.cedula,
  }) : commerceId = restaurant?.id ?? commerceId ?? 0,
       nombreLocal = restaurant?.nombreLocal ?? nombreLocal ?? '',
       direccion = restaurant?.direccion ?? direccion ?? '',
       telefono = restaurant?.telefono ?? telefono ?? '',
       abierto = restaurant?.abierto ?? abierto ?? false,
       super(key: key);

  // Constructor factory para compatibilidad
  factory RestaurantDetailsPage.fromRestaurant(Restaurant restaurant) {
    return RestaurantDetailsPage(
      restaurant: restaurant,
    );
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
    _promotionsFuture = PromotionService().getActivePromotions(commerceId: widget.commerceId);
    _reviewsFuture = BuyerReviewService().getRestaurantReviews(widget.commerceId);
    _loadFavorite();
    _loadReviewStats();
  }

  Future<List<Product>> _loadProducts() async {
    final allProducts = await ProductService().fetchProducts();
    final commerceProducts = allProducts.where((p) => p.commerceId == widget.commerceId).toList();
    // Extraer categorías únicas
    final categories = commerceProducts.map((p) => p.category).toSet().toList();
    setState(() {
      _categories = ['Todos', ...categories];
    });
    return commerceProducts;
  }

  Future<void> _loadFavorite() async {
    _isFavorite = await FavoritesService().isFavorite(widget.commerceId);
    setState(() {});
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService().toggleFavorite(widget.commerceId);
    await _loadFavorite();
  }

  Future<void> _loadReviewStats() async {
    final reviews = await BuyerReviewService().getRestaurantReviews(widget.commerceId);
    _totalReviews = reviews.length;
    if (_totalReviews > 0) {
      _averageRating = reviews.map((r) => (r['rating'] ?? 0.0) as num).reduce((a, b) => a + b) / _totalReviews;
    } else {
      _averageRating = 0.0;
    }
    setState(() {});
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' || 
        (product.category) == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  String _getTodaySchedule(Map<String, dynamic> horario) {
    final now = DateTime.now();
    final days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    final today = days[now.weekday - 1];
    if (horario.containsKey(today)) {
      // Quitar corchetes del valor
      final value = horario[today].toString().replaceAll(RegExp(r'[{}]'), '');
      return '$today: $value';
    }
    return 'Horario no disponible';
  }

  void _showFullSchedule(Map<String, dynamic> horario, ThemeData theme, bool abierto, bool isDark) {
    final Color modalColor = abierto
        ? (isDark ? Colors.green.shade800 : Colors.green.shade600)
        : (isDark ? Colors.red.shade800 : Colors.red.shade600);
    final diasES = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: modalColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horario completo', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            ...horario.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('${diasES[entry.key] ?? entry.key}: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  Expanded(child: Text(entry.value.toString().replaceAll(RegExp(r'[{}]'), ''), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getBankDisplay(String? bank) {
    if (bank == null || bank.isEmpty) return '';
    if (bank.startsWith('http')) {
      try {
        final uri = Uri.parse(bank);
        return uri.host;
      } catch (_) {
        return bank;
      }
    }
    return bank;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final secondaryText = theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
    final accentColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Consumer<CartService>(
        builder: (context, cartService, child) {
          int totalItems = cartService.items.fold(0, (sum, item) => sum + item.quantity);
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (totalItems > 0)
                  Positioned(
                    left: 15,
                    bottom: 15,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: const Text('Ver carrito'),
            backgroundColor: Colors.orange,
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            floating: false,
            pinned: true,
            backgroundColor: widget.abierto
                ? (isDark ? Colors.green.shade800 : Colors.green.shade600)
                : (isDark ? Colors.red.shade800 : Colors.red.shade600),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: widget.abierto
                        ? (isDark ? Colors.green.shade800 : Colors.green.shade600)
                        : (isDark ? Colors.red.shade800 : Colors.red.shade600),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               const SizedBox(height: 12), // Espacio para los botones flotantes
                              
                              
                              
                              
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo del restaurante
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: widget.logoUrl != null && widget.logoUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              widget.logoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.store, size: 40, color: Colors.grey.shade400),
                                            ),
                                          )
                                        : Icon(Icons.store, size: 40, color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(width: 14),
                                  
                                  
                                  
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.nombreLocal,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.orange, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              _averageRating.toStringAsFixed(1),
                                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            Text(' ($_totalReviews)', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: widget.abierto ? Colors.green : Colors.red,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                widget.abierto ? 'ABIERTO' : 'CERRADO',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (widget.tiempoEntrega != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.timer, size: 14, color: Colors.blue),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      widget.tiempoEntrega!,
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        // Dirección del restaurante
                                        Text(
                                          widget.direccion.replaceAll('\n', ' '),
                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.left,
                                        ),
                                        const SizedBox(height: 4),
                                        if (widget.horario != null && widget.horario!.isNotEmpty)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _getTodaySchedule(widget.horario!),
                                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => _showFullSchedule(widget.horario!, theme, widget.abierto, isDark),
                                                child: const Text('Ver todos'),
                                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                              ),
                                            ],
                                          ),
                                        if ((widget.logoUrl != null && widget.logoUrl!.isNotEmpty) || widget.abierto)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Pago móvil', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                                                if (widget.banco != null && widget.banco!.isNotEmpty)
                                                  Text('Banco: ${widget.banco}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                                if (widget.cedula != null && widget.cedula!.isNotEmpty)
                                                  Text('CI: ${widget.cedula}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                                if (widget.telefono.isNotEmpty)
                                                  Text('Teléfono: ${widget.telefono}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),



                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Botones flotantes arriba a la izquierda y derecha
                  // Positioned(
                  //   top: 8,
                  //   left: 8,
                  //   child: IconButton(
                  //     icon: Icon(Icons.arrow_back, color: Colors.white),
                  //     onPressed: () => Navigator.of(context).pop(),
                  //   ),
                  // ),
                  // Positioned(
                  //   top: 8,
                  //   right: 8,
                  //   child: IconButton(
                  //     icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent, size: 28),
                  //     onPressed: _toggleFavorite,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey.shade50,
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.orange.shade100,
                      checkmarkColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.orange.shade800 : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey.shade50,
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error: ${snapshot.error}'),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay productos disponibles'),
                          ],
                        ),
                      ),
                    );
                  }

                  final filteredProducts = _filterProducts(snapshot.data!);
                  if (filteredProducts.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No se encontraron productos'),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  );
                },
              ),
            ),
          ),
          // Promociones
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _promotionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final promotions = snapshot.data!;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Promociones activas', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...promotions.map((promo) => ListTile(
                        leading: promo['image_url'] != null ? Image.network(promo['image_url'], width: 40, height: 40) : null,
                        title: Text(promo['title'] ?? ''),
                        subtitle: Text(promo['description'] ?? ''),
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
          // Resumen de reseñas
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final reviews = snapshot.data!;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reseñas recientes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...reviews.take(2).map((review) => ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(review['customer_name'] ?? 'Cliente'),
                        subtitle: Text(review['comment'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            Text('${review['rating'] ?? ''}'),
                          ],
                        ),
                      )),
                      if (reviews.length > 2)
                        TextButton(
                          onPressed: () {
                            // Navegar a página de reseñas completas
                          },
                          child: const Text('Ver todas las reseñas'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showProductDetails(product);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: product.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.fastfood, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final cartService = Provider.of<CartService>(context, listen: false);
                            cartService.addToCart(CartItem(
                              id: product.id,
                              nombre: product.name,
                              precio: product.price,
                              quantity: 1,
                              imagen: product.image,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Producto agregado al carrito'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Agregar',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
      ),
    );
  }

  void _showProductDetails(Product product) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.dialogBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.image.isNotEmpty)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.shade100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.fastfood, size: 80, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Descripción',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final cartService = Provider.of<CartService>(context, listen: false);
                            cartService.addToCart(CartItem(
                              id: product.id,
                              nombre: product.name,
                              precio: product.price,
                              quantity: 1,
                              imagen: product.image,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Producto agregado al carrito'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Agregar al Carrito',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  Widget _buildScheduleTable(Map<String, dynamic> horario, ThemeData theme) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: horario.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Text(entry.key, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Text(entry.value.toString(), style: theme.textTheme.bodyMedium),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobilePaymentInfo(ThemeData theme) {
    // Aquí deberías obtener los datos de pago móvil del modelo Restaurant
    // Puedes pasarlos como parámetros o acceder a ellos desde widget
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pago móvil', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (widget.logoUrl != null && widget.logoUrl!.isNotEmpty)
          Text('Banco: ${widget.logoUrl!}', style: theme.textTheme.bodyMedium),
        if (widget.telefono.isNotEmpty)
          Text('Teléfono: ${widget.telefono}', style: theme.textTheme.bodyMedium),
        // Puedes agregar más campos según el modelo
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}