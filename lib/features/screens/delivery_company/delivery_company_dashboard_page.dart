import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_company_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';
import '../../utils/responsive_helper.dart';

class DeliveryCompanyDashboardPage extends StatefulWidget {
  const DeliveryCompanyDashboardPage({super.key});

  @override
  State<DeliveryCompanyDashboardPage> createState() => _DeliveryCompanyDashboardPageState();
}

class _DeliveryCompanyDashboardPageState extends State<DeliveryCompanyDashboardPage> {
  int _obsWindowHours = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<DeliveryCompanyService>();
      service.loadDashboard();
      service.loadObservability(windowHours: _obsWindowHours);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Empresa')),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, service, _) {
          if (service.dashboardLoading && service.dashboardData.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          if (service.dashboardError != null && service.dashboardData.isEmpty) {
            return _buildError(service.dashboardError!, () => service.loadDashboard());
          }

          final data = service.dashboardData;
          final company = data['company'] as Map<String, dynamic>? ?? {};
          final agentsCount = safeInt(data['agents_count']);
          final activeAgents = safeInt(data['active_agents']);
          final todayDeliveries = safeInt(data['today_deliveries']);
          final weekDeliveries = safeInt(data['week_deliveries']);
          final monthDeliveries = safeInt(data['month_deliveries']);
          final todayEarnings = _num(data['today_earnings']);
          final weekEarnings = _num(data['week_earnings']);
          final monthEarnings = _num(data['month_earnings']);
          final avgRating = _num(data['average_rating']);
          final obsSummary = service.observabilitySummary;
          final obsKpi = obsSummary['kpi'] is Map
              ? obsSummary['kpi'] as Map<String, dynamic>
              : <String, dynamic>{};
          final obsIncidents = service.observabilityIncidents;
          final obsHistory = service.observabilityHistory;
          final obsRunbooks = service.observabilityRunbooks;

          return RefreshIndicator(
            onRefresh: () async {
              await service.loadDashboard();
              await service.loadObservability(windowHours: _obsWindowHours);
            },
            child: ResponsiveCenter(
              maxWidth: 1000,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCompanyHeader(context, company),
                  const SizedBox(height: 16),
                  _buildDefaultPayoutCard(context, company),
                  const SizedBox(height: 16),
                  _buildStatusRow(context, agentsCount, activeAgents, avgRating),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Entregas'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metricCard(context, 'Hoy', '$todayDeliveries', AppColors.green),
                      const SizedBox(width: 8),
                      _metricCard(context, 'Semana', '$weekDeliveries', AppColors.blue),
                      const SizedBox(width: 8),
                      _metricCard(context, 'Mes', '$monthDeliveries', AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Ganancias'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metricCard(context, 'Hoy', '\$${todayEarnings.toStringAsFixed(2)}', AppColors.green),
                      const SizedBox(width: 8),
                      _metricCard(context, 'Semana', '\$${weekEarnings.toStringAsFixed(2)}', AppColors.blue),
                      const SizedBox(width: 8),
                      _metricCard(context, 'Mes', '\$${monthEarnings.toStringAsFixed(2)}', AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Observabilidad Delivery'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('24h'),
                        selected: _obsWindowHours == 24,
                        onSelected: (_) {
                          setState(() => _obsWindowHours = 24);
                          service.loadObservability(windowHours: _obsWindowHours);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('12h'),
                        selected: _obsWindowHours == 12,
                        onSelected: (_) {
                          setState(() => _obsWindowHours = 12);
                          service.loadObservability(windowHours: _obsWindowHours);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('6h'),
                        selected: _obsWindowHours == 6,
                        onSelected: (_) {
                          setState(() => _obsWindowHours = 6);
                          service.loadObservability(windowHours: _obsWindowHours);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildObservabilityCard(context, obsKpi, obsIncidents, obsHistory, obsRunbooks),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultPayoutCard(BuildContext context, Map<String, dynamic> company) {
    final cs = Theme.of(context).colorScheme;
    final defaultPct = safeDouble(company['default_payout_percentage'], 70.0);
    return InkWell(
      onTap: () => _showEditDefaultPayoutDialog(context, defaultPct),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.percent, color: AppColors.orange, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Porcentaje default (nuevos agentes)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${defaultPct.toStringAsFixed(0)}% del delivery_fee', style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 18, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  void _showEditDefaultPayoutDialog(BuildContext context, double currentPct) {
    final controller = TextEditingController(text: currentPct.toStringAsFixed(0));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Porcentaje default'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Porcentaje para nuevos agentes (0-100)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final pct = double.tryParse(controller.text.replaceAll(',', '.'));
              if (pct == null || pct < 0 || pct > 100) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa un número entre 0 y 100')));
                return;
              }
              Navigator.of(ctx).pop();
              final ok = await context.read<DeliveryCompanyService>().updateCompanySettings(defaultPayoutPercentage: pct);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Configuración actualizada' : 'Error al actualizar')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context, Map<String, dynamic> company) {
    final cs = Theme.of(context).colorScheme;
    final name = company['name'] ?? 'Mi Empresa';
    final isOpen = company['open'] == true;
    final isActive = company['active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.orange.withValues(alpha: 0.15),
            child: const Icon(Icons.local_shipping, color: AppColors.orange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _statusChip(isOpen ? 'Abierto' : 'Cerrado', isOpen ? AppColors.green : AppColors.red),
                    const SizedBox(width: 8),
                    _statusChip(
                      isActive ? 'Activo' : 'Inactivo',
                      isActive ? AppColors.blue : cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildStatusRow(BuildContext context, int total, int active, double rating) {
    return Row(
      children: [
        _statCard(context, Icons.people, '$total', 'Agentes', AppColors.blue),
        const SizedBox(width: 8),
        _statCard(context, Icons.circle, '$active', 'Activos', AppColors.green),
        const SizedBox(width: 8),
        _statCard(context, Icons.star, rating.toStringAsFixed(1), 'Rating', AppColors.orange),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.secondaryText(context))),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText(context)));
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildObservabilityCard(
    BuildContext context,
    Map<String, dynamic> kpi,
    List<Map<String, dynamic>> incidents,
    List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> runbooks,
  ) {
    final unassigned = safeInt(kpi['unassigned_over_threshold']);
    final frozen = safeInt(kpi['frozen_tracking_count']);
    final timeoutRatio = safeDouble(kpi['timeout_ratio_percent']);
    final avgAssign = safeDouble(kpi['avg_assignment_minutes']);

    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _statusChip('Sin asignar: $unassigned', AppColors.red),
              _statusChip('Tracking congelado: $frozen', AppColors.orange),
              _statusChip('Timeout: ${timeoutRatio.toStringAsFixed(2)}%', AppColors.purple),
              _statusChip('Asignación: ${avgAssign.toStringAsFixed(2)} min', AppColors.blue),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Incidentes activos (${incidents.length})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (incidents.isEmpty)
            Text(
              'Sin incidentes activos.',
              style: TextStyle(color: AppColors.secondaryText(context)),
            )
          else
            for (final incident in incidents.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '• ${safeString(incident['event_code'])} (orden #${safeInt(incident['order_id'])})',
                  style: TextStyle(color: AppColors.primaryText(context), fontSize: 13),
                ),
              ),
          const SizedBox(height: 10),
          const Text(
            'Historico reciente',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (history.isEmpty)
            Text(
              'Sin snapshots historicos.',
              style: TextStyle(color: AppColors.secondaryText(context)),
            )
          else
            for (final snapshot in history.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '• ${safeString(snapshot['created_at'])} · TTA ${safeDouble(snapshot['avg_assignment_minutes']).toStringAsFixed(2)}m',
                  style: TextStyle(color: AppColors.primaryText(context), fontSize: 12),
                ),
              ),
          const SizedBox(height: 10),
          const Text(
            'Runbooks',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (runbooks.isEmpty)
            Text(
              'Sin runbooks.',
              style: TextStyle(color: AppColors.secondaryText(context)),
            )
          else
            for (final rb in runbooks.take(2))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '• ${safeString(rb['title'])}',
                  style: TextStyle(color: AppColors.primaryText(context), fontSize: 12),
                ),
              ),
        ],
      ),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
