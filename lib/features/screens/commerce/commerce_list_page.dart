import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_list_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/models/my_commerce.dart';
import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:zonix/features/screens/commerce/commerce_add_restaurant_page.dart';
import 'package:zonix/features/screens/commerce/commerce_detail_page.dart';

/// Pantalla "Mis Restaurantes" - lista de comercios del usuario (multi-restaurante).
/// Diseño estilo CorralX: cards con icono, stats, badge Principal, acciones Ver|Editar|Eliminar.
/// Si [embedded] es true, solo muestra el contenido sin Scaffold/AppBar (para Mi Perfil).
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
        title: const Text('Mis Restaurantes'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 80, color: AppColors.green.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              const Text(
                'No tienes restaurantes registrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega tu primer restaurante con el botón de abajo',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildAddButton(),
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
              padding: const EdgeInsets.all(16),
              child: _buildAddButton(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final c = _commerces[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _CommerceCard(
                    commerce: c,
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
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _addRestaurant,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Restaurante'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Card de restaurante estilo CorralX: icono, nombre, RIF, descripción, badge Principal, stats, acciones.
class _CommerceCard extends StatelessWidget {
  final MyCommerce commerce;
  final VoidCallback onVer;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _CommerceCard({
    required this.commerce,
    required this.onVer,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final c = commerce;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: c.image != null && c.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            c.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppColors.green, size: 28),
                          ),
                        )
                      : const Icon(Icons.store, color: AppColors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.businessName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (c.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (c.taxId != null && c.taxId!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'RIF: ${c.taxId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (c.address != null && c.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          c.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.star,
                  label: 'Rating',
                  value: c.stats != null ? c.stats!.rating.toString() : '-',
                ),
                _StatItem(
                  icon: Icons.shopping_bag,
                  label: 'Ventas',
                  value: c.stats?.ventas.toString() ?? '-',
                ),
                _StatItem(
                  icon: Icons.inventory_2,
                  label: 'Productos',
                  value: c.stats?.productos.toString() ?? '-',
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onVer,
                  child: const Text('Ver'),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                TextButton(
                  onPressed: onEditar,
                  child: const Text('Editar'),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                TextButton(
                  onPressed: onEliminar,
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
