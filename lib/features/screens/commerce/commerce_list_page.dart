import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/features/services/commerce_list_service.dart';
import 'package:zonix/models/my_commerce.dart';
import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:zonix/features/screens/commerce/commerce_add_restaurant_page.dart';
import 'package:zonix/features/screens/commerce/commerce_detail_page.dart';

/// Pantalla "Mis Comercios" - lista de comercios del usuario (multi-restaurante).
/// Diseño Stitch: cards con icono, badge Principal, stats en pills, botones Ver|Editar|Eliminar.
/// Si [embedded] es true, solo muestra el contenido sin Scaffold/AppBar (para Mi Perfil).

// Colores del template Stitch (code.html)
const Color _stitchPrimary = Color(0xFF3399FF);
const Color _stitchSurfaceDark = Color(0xFF182430);
const Color _stitchSurfaceLighter = Color(0xFF21303E);
const Color _stitchYellow400 = Color(0xFFFACC15);   // star
const Color _stitchGreen400 = Color(0xFF4ADE80);   // shopping_bag
const Color _stitchPurple400 = Color(0xFFA78BFA);  // inventory_2
class CommerceListPage extends StatefulWidget {
  const CommerceListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CommerceListPage> createState() => _CommerceListPageState();
}

class _CommerceListPageState extends State<CommerceListPage> {
  List<MyCommerce> _commerces = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCommerces();
  }

  Future<void> _loadCommerces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CommerceListService.getMyCommerces();
      if (mounted) {
        setState(() {
          _commerces = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _setPrimaryAndOpenConfig(MyCommerce commerce) async {
    if (!commerce.isPrimary) {
      try {
        await CommerceListService.setPrimary(commerce.id);
        await _loadCommerces();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
        return;
      }
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CommerceDataPage(),
        ),
      ).then((_) => _loadCommerces());
    }
  }

  Future<void> _addRestaurant() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CommerceAddRestaurantPage(),
      ),
    );
    if (added == true && mounted) {
      _loadCommerces();
    }
  }

  void _onVer(MyCommerce c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommerceDetailPage(commerce: c),
      ),
    ).then((_) => _loadCommerces());
  }

  void _onEditar(MyCommerce c) => _setPrimaryAndOpenConfig(c);

  void _onEliminar(MyCommerce c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar restaurante'),
        content: Text(
          '¿Eliminar "${c.businessName}"? Esta acción no está disponible aún.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Comercios', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCommerces,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_commerces.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 80, color: _stitchPrimary.withValues(alpha: 0.4)),
              const SizedBox(height: 24),
              Text(
                'No tienes restaurantes registrados',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega tu primer restaurante con el botón de abajo',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildAddButton(),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommerces,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildAddButton(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final c = _commerces[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // gap-4 template
                  child: _CommerceCard(
                    commerce: c,
                    index: index,
                    onVer: () => _onVer(c),
                    onEditar: () => _onEditar(c),
                    onEliminar: () => _onEliminar(c),
                  ),
                );
              },
              childCount: _commerces.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24), // mb-6: misma separación con las cards
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addRestaurant,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: _stitchPrimary,
              borderRadius: BorderRadius.circular(24), // puntas bien redondeadas
              boxShadow: [
                BoxShadow(
                  color: _stitchPrimary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Agregar Restaurante',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de comercio estilo Stitch: icono 64x64, nombre, badge Principal, RIF, dirección, stats en pills, botones Ver|Editar|Eliminar.
class _CommerceCard extends StatelessWidget {
  final MyCommerce commerce;
  final VoidCallback onVer;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final int index;

  const _CommerceCard({
    required this.commerce,
    required this.onVer,
    required this.onEditar,
    required this.onEliminar,
    this.index = 0,
  });

  // Colores iconos template: blue-400, orange-400, pink-400
  Color _iconColorForIndex(int i) {
    switch (i % 3) {
      case 0:
        return const Color(0xFF60A5FA); // blue-400
      case 1:
        return const Color(0xFFFB923C); // orange-400
      default:
        return const Color(0xFFF472B6); // pink-400
    }
  }

  IconData _iconForCommerce(MyCommerce c) {
    final name = (c.businessName.toLowerCase());
    if (name.contains('pizza')) return Icons.local_pizza;
    if (name.contains('shake') || name.contains('helado') || name.contains('ice')) return Icons.icecream;
    return Icons.store;
  }

  @override
  Widget build(BuildContext context) {
    final c = commerce;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? _stitchSurfaceDark : theme.colorScheme.surface;
    final surfaceLighter = isDark ? _stitchSurfaceLighter : theme.colorScheme.surfaceContainerLow;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.outline.withValues(alpha: 0.2);
    final iconColor = _iconColorForIndex(index);
    final iconData = _iconForCommerce(c);

    final rating = c.stats?.rating.toString() ?? '0.0';
    final ventas = c.stats?.ventas.toString() ?? '0';
    final productos = c.stats?.productos.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2), // bg-*-500/20
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                  ),
                  child: c.image != null && c.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            c.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(iconData, color: iconColor, size: 32),
                          ),
                        )
                      : Icon(iconData, color: iconColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              c.businessName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (c.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _stitchPrimary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _stitchPrimary.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'Principal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _stitchPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (c.taxId != null && c.taxId!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'RIF: ${c.taxId}',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (c.address != null && c.address!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          c.address!,
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // mb-4
            Row(
              children: [
                _StatPill(
                  icon: Icons.star,
                  iconColor: _stitchYellow400,
                  value: rating,
                  surfaceLighter: surfaceLighter,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.shopping_bag,
                  iconColor: _stitchGreen400,
                  value: '$ventas Ventas',
                  surfaceLighter: surfaceLighter,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.inventory_2,
                  iconColor: _stitchPurple400,
                  value: '$productos Prod.',
                  surfaceLighter: surfaceLighter,
                  borderColor: borderColor,
                ),
              ],
            ),
            const SizedBox(height: 20), // mb-5
            Container(height: 1, color: borderColor), // border-t
            const SizedBox(height: 16), // pt-4
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: surfaceLighter,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onVer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'Ver',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: surfaceLighter,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onEditar,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'Editar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.red.withValues(alpha: 0.1), // bg-red-500/10
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                    child: InkWell(
                      onTap: onEliminar,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'Eliminar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color surfaceLighter;
  final Color borderColor;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.surfaceLighter,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceLighter,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
