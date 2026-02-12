import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_list_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/models/my_commerce.dart';
import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:zonix/features/screens/commerce/commerce_add_restaurant_page.dart';

/// Pantalla "Mis Restaurantes" - lista de comercios del usuario (multi-restaurante).
/// Permite seleccionar el activo y agregar nuevos.
class CommerceListPage extends StatefulWidget {
  const CommerceListPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Restaurantes'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRestaurant,
        icon: const Icon(Icons.add),
        label: const Text('Agregar restaurante'),
        backgroundColor: AppColors.purple,
      ),
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
              Icon(Icons.store_outlined, size: 80, color: AppColors.purple.withValues(alpha: 0.5)),
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
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommerces,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _commerces.length,
        itemBuilder: (context, index) {
          final c = _commerces[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                backgroundImage: c.image != null && c.image!.isNotEmpty
                    ? NetworkImage(c.image!)
                    : null,
                child: c.image == null || c.image!.isEmpty
                    ? const Icon(Icons.store, color: Colors.white)
                    : null,
              ),
              title: Row(
                children: [
                  Expanded(child: Text(c.businessName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (c.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Activo', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              subtitle: Text(c.address ?? '-'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _setPrimaryAndOpenConfig(c),
            ),
          );
        },
      ),
    );
  }
}
