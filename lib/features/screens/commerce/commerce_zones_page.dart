import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';

/// Read-only view of delivery zones for commerce users.
/// Zones are managed by the Admin via AdminDeliveryConfigPage.
class CommerceZonesPage extends StatefulWidget {
  const CommerceZonesPage({super.key});

  @override
  State<CommerceZonesPage> createState() => _CommerceZonesPageState();
}

class _CommerceZonesPageState extends State<CommerceZonesPage> {
  List<Map<String, dynamic>> _zones = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadZones());
  }

  Future<void> _loadZones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final zones = await context.read<AdminService>().getDeliveryZones();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Zonas de entrega')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.error(context)),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.secondaryText(context))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadZones,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadZones,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.blue.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Las zonas de entrega son configuradas por el administrador de Zonix Eats.',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.white70
                                      : AppColors.blueDark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_zones.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No hay zonas de entrega configuradas',
                              style: TextStyle(
                                  color: AppColors.secondaryText(context)),
                            ),
                          ),
                        )
                      else
                        ..._zones.map((z) => _zoneCard(z, isDark)),
                    ],
                  ),
                ),
    );
  }

  Widget _zoneCard(Map<String, dynamic> zone, bool isDark) {
    final name = safeString(zone['name'], 'Zona');
    final baseFee = safeDouble(zone['base_fee']);
    final perKmFee = safeDouble(zone['per_km_fee']);
    final minFee = safeDouble(zone['min_fee']);
    final maxFee = safeDouble(zone['max_fee']);
    final isActive = zone['is_active'] == true || zone['is_active'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.white12 : AppColors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined,
                  size: 18, color: AppColors.secondaryText(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.green : AppColors.red)
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    color: isActive ? AppColors.green : AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (baseFee > 0)
                _feeChip('Base', '\$${baseFee.toStringAsFixed(2)}'),
              if (perKmFee > 0)
                _feeChip('Por km', '\$${perKmFee.toStringAsFixed(2)}'),
              if (minFee > 0)
                _feeChip('Mín', '\$${minFee.toStringAsFixed(2)}'),
              if (maxFee > 0)
                _feeChip('Máx', '\$${maxFee.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feeChip(String label, String value) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.secondaryText(context),
      ),
    );
  }
}
