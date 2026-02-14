import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/models/cart_item.dart';
import 'package:zonix/models/restaurant.dart';
import 'package:zonix/features/services/restaurant_service.dart';
import 'package:zonix/features/screens/restaurants/restaurant_details_page.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:logger/logger.dart';

// Colores base (primary y accent se mantienen en ambos modos)
const Color _kPrimary = Color(0xFF3399FF);
const Color _kAccentYellow = Color(0xFFFFB800);

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Logger logger = Logger();
  final TextEditingController _instructionsController = TextEditingController();
  int _quantity = 1;
  bool _isLoading = false;
  late Future<Restaurant?> _restaurantFuture;
  Restaurant? _restaurant;
  final Set<int> _selectedExtraIds = {};
  final Set<int> _selectedPreferenceIds = {};

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _backgroundColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F1923) : Colors.white;

  Color _cardColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A2530) : AppColors.grayLight;

  Color _borderColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2D3A48) : Colors.black12;

  Color _textPrimary(BuildContext context) =>
      AppColors.primaryText(context);

  Color _textSecondary(BuildContext context) =>
      AppColors.secondaryText(context);

  @override
  void initState() {
    super.initState();
    _restaurantFuture = _loadRestaurant();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _extrasTotal {
    double sum = 0;
    for (final e in widget.product.extras) {
      if (_selectedExtraIds.contains(e.id)) sum += e.price;
    }
    return sum;
  }

  double get _unitTotal => widget.product.price + _extrasTotal;

  double get _total => _unitTotal * _quantity;

  String _buildNotes() {
    final parts = <String>[];
    if (_selectedExtraIds.isNotEmpty) {
      final names = widget.product.extras
          .where((e) => _selectedExtraIds.contains(e.id))
          .map((e) => e.name)
          .join(', ');
      if (names.isNotEmpty) parts.add('Extras: $names');
    }
    if (_selectedPreferenceIds.isNotEmpty) {
      final names = widget.product.preferences
          .where((p) => _selectedPreferenceIds.contains(p.id))
          .map((p) => p.name)
          .join(', ');
      if (names.isNotEmpty) parts.add('Preferencias: $names');
    }
    final instructions = _instructionsController.text.trim();
    if (instructions.isNotEmpty) {
      parts.add('Instrucciones: $instructions');
    }
    return parts.isEmpty ? '' : parts.join('. ');
  }

  Future<Restaurant?> _loadRestaurant() async {
    try {
      final restaurantService = RestaurantService();
      return await restaurantService.fetchRestaurantDetails2(widget.product.commerceId);
    } catch (e, stack) {
      logger.e('Error loading restaurant', error: e, stackTrace: stack);
      return null;
    }
  }

  void _navigateToRestaurant() async {
    if (_restaurant == null) return;
    setState(() => _isLoading = true);
    try {
      final r = _restaurant!;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailsPage(
            commerceId: r.id,
            nombreLocal: r.nombreLocal,
            direccion: r.direccion,
            telefono: r.telefono,
            abierto: r.abierto,
            horario: r.horario,
            logoUrl: r.logoUrl,
          ),
        ),
      );
    } catch (e) {
      logger.e('Navigation error', error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final heroHeight = mediaQuery.size.height * 0.45;

    final isDark = _isDark(context);
    return Scaffold(
      backgroundColor: _backgroundColor(context),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildHeroImage(context, heroHeight),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _backgroundColor(context),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDragHandle(context),
                            const SizedBox(height: 20),
                            _buildProductHeader(context, _total),
                            const SizedBox(height: 16),
                            _buildDescription(context),
                            const SizedBox(height: 16),
                            _buildTags(context),
                            const SizedBox(height: 24),
                            _buildRestaurantLink(context),
                            const SizedBox(height: 24),
                            Divider(color: _borderColor(context), height: 1),
                            const SizedBox(height: 24),
                            _buildCustomizationSection(context),
                            const SizedBox(height: 24),
                            _buildPreferencesSection(context),
                            const SizedBox(height: 24),
                            _buildSpecialInstructions(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _buildTopButtons(context),
            _buildBottomBar(context, cartService, _total),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, double height) {
    final bgColor = _backgroundColor(context);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImage(
              imageUrl: widget.product.image,
              productName: widget.product.name,
              width: double.infinity,
              height: height,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    bgColor.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleButton(
              context: context,
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
            _circleButton(
              context: context,
              icon: Icons.favorite_border,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 6,
        decoration: BoxDecoration(
          color: _borderColor(context),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context, double total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.product.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textPrimary(context),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kAccentYellow,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 16, color: _kAccentYellow),
                const SizedBox(width: 4),
                Text(
                  '${widget.product.rating > 0 ? widget.product.rating.toStringAsFixed(1) : '-'} (${widget.product.reviewCount > 0 ? _formatCount(widget.product.reviewCount) : '0'})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _textSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      widget.product.description.isNotEmpty ? widget.product.description : 'Sin descripción',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _textSecondary(context),
        height: 1.5,
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    final tags = <String>[];
    if (widget.product.rating >= 4.5) tags.add('Popular');
    if (widget.product.category.isNotEmpty) tags.add(widget.product.category);
    if (widget.product.preparationTime > 0) {
      tags.add('${widget.product.preparationTime}-${widget.product.preparationTime + 10} min');
    }
    if (tags.isEmpty) tags.addAll(['Popular', '20-30 min']);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: tags.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isFirst ? _kPrimary.withValues(alpha: 0.2) : Colors.transparent,
            border: Border.all(
              color: isFirst ? _kPrimary.withValues(alpha: 0.3) : _borderColor(context),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            e.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isFirst ? _kPrimary : _textSecondary(context),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRestaurantLink(BuildContext context) {
    return FutureBuilder<Restaurant?>(
      future: _restaurantFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)));
        }
        if (snapshot.hasError || snapshot.data == null) return const SizedBox.shrink();
        _restaurant = snapshot.data;
        return GestureDetector(
          onTap: _isLoading ? null : _navigateToRestaurant,
          child: Text(
            'Ver restaurante: ${_restaurant?.nombreLocal ?? ''}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kPrimary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomizationSection(BuildContext context) {
    if (widget.product.extras.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Personaliza tu orden',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _cardColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Opcional',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _textSecondary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.product.extras.map((e) => _buildOptionTile(
              context,
              e.name,
              '+ \$${e.price.toStringAsFixed(2)}',
              _selectedExtraIds.contains(e.id),
              () => setState(() {
                    if (_selectedExtraIds.contains(e.id)) {
                      _selectedExtraIds.remove(e.id);
                    } else {
                      _selectedExtraIds.add(e.id);
                    }
                  }),
            )),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    if (widget.product.preferences.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferencias',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimary(context),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.product.preferences.map((p) => _buildOptionTile(
              context,
              p.name,
              null,
              _selectedPreferenceIds.contains(p.id),
              () => setState(() {
                    if (_selectedPreferenceIds.contains(p.id)) {
                      _selectedPreferenceIds.remove(p.id);
                    } else {
                      _selectedPreferenceIds.add(p.id);
                    }
                  }),
            )),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String label,
    String? price,
    bool value,
    VoidCallback onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (_) => onChanged(),
              fillColor: WidgetStateProperty.all(Colors.transparent),
              checkColor: _kPrimary,
              side: BorderSide(color: _borderColor(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textPrimary(context),
              ),
            ),
          ),
          if (price != null)
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instrucciones Especiales',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor(context)),
          ),
          child: TextField(
            controller: _instructionsController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Ej: Salsa aparte, servilletas extra...',
              hintStyle: GoogleFonts.plusJakartaSans(color: _textSecondary(context), fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    CartService cartService,
    double total,
  ) {
    final isDark = _isDark(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? _cardColor(context).withValues(alpha: 0.95)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? _backgroundColor(context) : AppColors.grayLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: _textPrimary(context), size: 20),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: _textPrimary(context), size: 20),
                    onPressed: () => setState(() => _quantity++),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Material(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    final notes = _buildNotes();
                    cartService.addToCart(CartItem(
                      id: widget.product.id,
                      nombre: widget.product.name,
                      precio: _unitTotal,
                      quantity: _quantity,
                      image: widget.product.image,
                      notes: notes.isEmpty ? null : notes,
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto añadido al carrito')),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Agregar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
