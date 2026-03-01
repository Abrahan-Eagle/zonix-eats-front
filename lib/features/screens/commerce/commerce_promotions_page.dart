import 'package:flutter/material.dart';
import 'package:zonix/features/screens/commerce/commerce_promotion_form_page.dart';
import 'package:zonix/features/services/commerce_promotion_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommercePromotionsPage extends StatefulWidget {
  const CommercePromotionsPage({super.key});

  @override
  State<CommercePromotionsPage> createState() => _CommercePromotionsPageState();
}

class _CommercePromotionsPageState extends State<CommercePromotionsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CommercePromotionService.getPromotions();
      if (mounted) {
        setState(() {
          _promotions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promociones')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      body: _promotions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay promociones'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _promotions.length,
                itemBuilder: (context, i) {
                  final p = _promotions[i] is Map
                      ? _promotions[i] as Map
                      : <String, dynamic>{};
                  final active = p['is_active'] == true;
                  final id = p['id'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(p['title'] ?? p['name'] ?? 'Promoción'),
                      subtitle: Text(
                        (p['description'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Chip(
                        label: Text(active ? 'Activa' : 'Inactiva'),
                        backgroundColor: active ? AppColors.green : Colors.grey,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        if (id != null) {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommercePromotionFormPage(
                                promotionId: id is int ? id : int.tryParse(id.toString()),
                                initialData: Map<String, dynamic>.from(p),
                              ),
                            ),
                          );
                          if (result == true) _loadData();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'commerce_promotions_add',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CommercePromotionFormPage(),
            ),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
