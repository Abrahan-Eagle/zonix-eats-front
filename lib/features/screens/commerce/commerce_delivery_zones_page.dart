import 'package:flutter/material.dart';
import 'package:zonix/features/screens/commerce/commerce_delivery_zone_form_page.dart';
import 'package:zonix/features/services/commerce_delivery_zone_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceDeliveryZonesPage extends StatefulWidget {
  const CommerceDeliveryZonesPage({Key? key}) : super(key: key);

  @override
  State<CommerceDeliveryZonesPage> createState() =>
      _CommerceDeliveryZonesPageState();
}

class _CommerceDeliveryZonesPageState extends State<CommerceDeliveryZonesPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _zones = [];

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
      final list = await CommerceDeliveryZoneService.getDeliveryZones();
      if (mounted) {
        setState(() {
          _zones = list;
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
        appBar: AppBar(title: const Text('Zonas de delivery')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.red),
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
      appBar: AppBar(title: const Text('Zonas de delivery')),
      body: _zones.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay zonas configuradas'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _zones.length,
                itemBuilder: (context, i) {
                  final z = _zones[i] is Map
                      ? _zones[i] as Map
                      : <String, dynamic>{};
                  final name = z['name'] ?? 'Zona ${z['id'] ?? ''}';
                  final radius = z['radius'] ?? 0;
                  final fee = (z['delivery_fee'] ?? 0) as num;
                  final time = z['delivery_time'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: AppColors.blue),
                      title: Text(name.toString()),
                      subtitle: Text(
                        'Radio: ${radius} km · Tarifa: \$${fee.toStringAsFixed(2)}'
                        '${time != null ? ' · ${time} min' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommerceDeliveryZoneFormPage(
                              zoneId: z['id'] is int ? z['id'] as int? : int.tryParse(z['id']?.toString() ?? ''),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommerceDeliveryZoneFormPage(),
            ),
          );
        },
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
