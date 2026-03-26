import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';
import '../../utils/responsive_helper.dart';

class AdminDeliveryConfigPage extends StatelessWidget {
  const AdminDeliveryConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: AppBar(
          title: const Text('Configuración Delivery'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.headerGradientStart(context),
                  AppColors.headerGradientMid(context),
                ],
              ),
            ),
          ),
          foregroundColor: AppColors.white,
          bottom: const TabBar(
            indicatorColor: AppColors.yellow,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white60,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Tarifa Global'),
              Tab(text: 'Zonas de Entrega'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalRateTab(),
            _DeliveryZonesTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Tab 1: Tarifa Global ───────────────────────

class _GlobalRateTab extends StatefulWidget {
  const _GlobalRateTab();

  @override
  State<_GlobalRateTab> createState() => _GlobalRateTabState();
}

class _GlobalRateTabState extends State<_GlobalRateTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _baseCostCtrl = TextEditingController();
  final _costPerKmCtrl = TextEditingController();
  final _freeKmCtrl = TextEditingController();
  final _feeMinCtrl = TextEditingController();
  final _feeMaxCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  @override
  void dispose() {
    _baseCostCtrl.dispose();
    _costPerKmCtrl.dispose();
    _freeKmCtrl.dispose();
    _feeMinCtrl.dispose();
    _feeMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await context.read<AdminService>().getDeliverySettings();
      if (!mounted) return;
      _baseCostCtrl.text = safeString(data['base_cost']);
      _costPerKmCtrl.text = safeString(data['cost_per_km']);
      _freeKmCtrl.text = safeString(data['free_km']);
      _feeMinCtrl.text = safeString(data['fee_min']);
      _feeMaxCtrl.text = safeString(data['fee_max']);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await context.read<AdminService>().updateDeliverySettings({
        'base_cost': double.tryParse(_baseCostCtrl.text) ?? 0,
        'cost_per_km': double.tryParse(_costPerKmCtrl.text) ?? 0,
        'free_km': double.tryParse(_freeKmCtrl.text) ?? 0,
        'fee_min': double.tryParse(_feeMinCtrl.text) ?? 0,
        'fee_max': double.tryParse(_feeMaxCtrl.text) ?? 0,
      });
      if (!mounted) return;
      _snack('Tarifa actualizada correctamente');
    } catch (e) {
      if (!mounted) return;
      _snack('Error: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadSettings,
      color: AppColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Form(
          key: _formKey,
          child: ResponsiveCenter(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(),
                const SizedBox(height: 24),
                _field(
                    _baseCostCtrl, 'Costo base (\$)', Icons.payments_rounded),
                const SizedBox(height: 16),
                _field(_costPerKmCtrl, 'Costo por km (\$)',
                    Icons.straighten_rounded),
                const SizedBox(height: 16),
                _field(_freeKmCtrl, 'Km gratis', Icons.card_giftcard_rounded),
                const SizedBox(height: 16),
                _field(_feeMinCtrl, 'Tarifa mínima (\$)',
                    Icons.arrow_downward_rounded),
                const SizedBox(height: 16),
                _field(_feeMaxCtrl, 'Tarifa máxima (\$)',
                    Icons.arrow_upward_rounded),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Guardando…' : 'Guardar cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.blue.withAlpha(25) : AppColors.blueLight50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.blue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estos valores se usan para calcular la tarifa de delivery '
              'cuando no hay zona específica.',
              style: TextStyle(
                fontSize: 13,
                color: _isDark ? AppColors.white70 : AppColors.gray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        if (double.tryParse(v.trim()) == null) return 'Número inválido';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _isDark ? AppColors.grayDark : AppColors.grayLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText(context)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────── Tab 2: Zonas de Entrega ────────────────────────

class _DeliveryZonesTab extends StatefulWidget {
  const _DeliveryZonesTab();

  @override
  State<_DeliveryZonesTab> createState() => _DeliveryZonesTabState();
}

class _DeliveryZonesTabState extends State<_DeliveryZonesTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _zones = [];
  bool _isLoading = true;
  String? _error;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadZones());
  }

  Future<void> _loadZones() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final zones = await context.read<AdminService>().getDeliveryZones();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) return _buildErrorState();

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: _zones.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadZones,
              color: AppColors.blue,
              child: ResponsiveCenter(
                maxWidth: 900,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _zones.length,
                  itemBuilder: (_, i) => _zoneCard(_zones[i], i),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showZoneDialog(),
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva zona'),
      ),
    );
  }

  Widget _zoneCard(Map<String, dynamic> zone, int index) {
    final name = safeString(zone['name'], 'Sin nombre');
    final radius = safeDouble(zone['radius']);
    final fee = safeDouble(zone['delivery_fee']);
    final time = safeString(zone['delivery_time'], '—');
    final active = zone['is_active'] == true || zone['is_active'] == 1;

    return Dismissible(
      key: ValueKey(zone['id'] ?? index),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(zone),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.cardBg(context),
        elevation: _isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: _isDark
              ? const BorderSide(color: AppColors.white12)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _showZoneDialog(zone: zone),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                    ),
                    _activeBadge(active),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _zoneStat(
                        Icons.radar_rounded, '${radius.toStringAsFixed(1)} km'),
                    _zoneStat(
                        Icons.payments_rounded, '\$${fee.toStringAsFixed(2)}'),
                    _zoneStat(Icons.timer_rounded, time),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _zoneStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText(context)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _activeBadge(bool active) {
    final color = active ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        active ? 'Activa' : 'Inactiva',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Map<String, dynamic> zone) async {
    final service = context.read<AdminService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar zona'),
        content: Text(
            '¿Eliminar "${safeString(zone['name'])}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await service.deleteDeliveryZone(safeInt(zone['id']));
        if (!mounted) return false;
        _snack('Zona eliminada');
        await _loadZones();
        return true;
      } catch (e) {
        if (!mounted) return false;
        _snack('Error al eliminar: $e', isError: true);
      }
    }
    return false;
  }

  void _showZoneDialog({Map<String, dynamic>? zone}) {
    final isEditing = zone != null;
    final nameCtrl = TextEditingController(text: safeString(zone?['name']));
    final latCtrl =
        TextEditingController(text: safeString(zone?['center_lat']));
    final lngCtrl =
        TextEditingController(text: safeString(zone?['center_lng']));
    final radiusCtrl = TextEditingController(text: safeString(zone?['radius']));
    final feeCtrl =
        TextEditingController(text: safeString(zone?['delivery_fee']));
    final timeCtrl =
        TextEditingController(text: safeString(zone?['delivery_time']));
    final descCtrl =
        TextEditingController(text: safeString(zone?['description']));
    bool isActive = zone?['is_active'] == true || zone?['is_active'] == 1;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar zona' : 'Nueva zona'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dialogField(nameCtrl, 'Nombre', required: true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _dialogField(latCtrl, 'Latitud',
                                    isNumber: true)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _dialogField(lngCtrl, 'Longitud',
                                    isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _dialogField(radiusCtrl, 'Radio (km)',
                                    isNumber: true, required: true)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _dialogField(feeCtrl, 'Tarifa (\$)',
                                    isNumber: true, required: true)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _dialogField(timeCtrl, 'Tiempo estimado'),
                        const SizedBox(height: 12),
                        _dialogField(descCtrl, 'Descripción'),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Activa'),
                          value: isActive,
                          onChanged: (v) => setDialogState(() => isActive = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    await _saveZone(
                      id: safeInt(zone?['id']),
                      isEditing: isEditing,
                      name: nameCtrl.text.trim(),
                      lat: latCtrl.text.trim(),
                      lng: lngCtrl.text.trim(),
                      radius: radiusCtrl.text.trim(),
                      fee: feeCtrl.text.trim(),
                      time: timeCtrl.text.trim(),
                      desc: descCtrl.text.trim(),
                      active: isActive,
                    );
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    bool isNumber = false,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Future<void> _saveZone({
    required int id,
    required bool isEditing,
    required String name,
    required String lat,
    required String lng,
    required String radius,
    required String fee,
    required String time,
    required String desc,
    required bool active,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (lat.isNotEmpty) 'center_lat': double.tryParse(lat),
      if (lng.isNotEmpty) 'center_lng': double.tryParse(lng),
      'radius': double.tryParse(radius) ?? 0,
      'delivery_fee': double.tryParse(fee) ?? 0,
      if (time.isNotEmpty) 'delivery_time': time,
      if (desc.isNotEmpty) 'description': desc,
      'is_active': active,
    };

    try {
      final service = context.read<AdminService>();
      if (isEditing) {
        await service.updateDeliveryZone(id, body);
      } else {
        await service.createDeliveryZone(body);
      }
      if (!mounted) return;
      _snack(isEditing ? 'Zona actualizada' : 'Zona creada');
      await _loadZones();
    } catch (e) {
      if (!mounted) return;
      _snack('Error: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded,
              size: 64, color: AppColors.secondaryText(context)),
          const SizedBox(height: 12),
          Text(
            'No hay zonas de entrega',
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulsa + para crear la primera',
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText(context)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadZones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
