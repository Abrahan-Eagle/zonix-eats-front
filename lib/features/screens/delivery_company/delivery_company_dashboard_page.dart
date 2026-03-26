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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryCompanyService>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Empresa')),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, service, _) {
          if (service.dashboardLoading && service.dashboardData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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

          return RefreshIndicator(
            onRefresh: () => service.loadDashboard(),
            child: ResponsiveCenter(
              maxWidth: 1000,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCompanyHeader(company, isDark),
                  const SizedBox(height: 16),
                  _buildDefaultPayoutCard(company, isDark),
                  const SizedBox(height: 16),
                  _buildStatusRow(agentsCount, activeAgents, avgRating, isDark),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Entregas'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metricCard('Hoy', '$todayDeliveries', AppColors.green, isDark),
                      const SizedBox(width: 8),
                      _metricCard('Semana', '$weekDeliveries', AppColors.blue, isDark),
                      const SizedBox(width: 8),
                      _metricCard('Mes', '$monthDeliveries', AppColors.purple, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Ganancias'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metricCard('Hoy', '\$${todayEarnings.toStringAsFixed(2)}', AppColors.green, isDark),
                      const SizedBox(width: 8),
                      _metricCard('Semana', '\$${weekEarnings.toStringAsFixed(2)}', AppColors.blue, isDark),
                      const SizedBox(width: 8),
                      _metricCard('Mes', '\$${monthEarnings.toStringAsFixed(2)}', AppColors.purple, isDark),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultPayoutCard(Map<String, dynamic> company, bool isDark) {
    final defaultPct = safeDouble(company['default_payout_percentage'], 70.0);
    return InkWell(
      onTap: () => _showEditDefaultPayoutDialog(context, defaultPct),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grayDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.white12 : AppColors.black12),
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

  Widget _buildCompanyHeader(Map<String, dynamic> company, bool isDark) {
    final name = company['name'] ?? 'Mi Empresa';
    final isOpen = company['open'] == true;
    final isActive = company['active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.white12 : AppColors.black12),
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
                    _statusChip(isActive ? 'Activo' : 'Inactivo', isActive ? AppColors.blue : AppColors.gray),
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

  Widget _buildStatusRow(int total, int active, double rating, bool isDark) {
    return Row(
      children: [
        _statCard(Icons.people, '$total', 'Agentes', AppColors.blue, isDark),
        const SizedBox(width: 8),
        _statCard(Icons.circle, '$active', 'Activos', AppColors.green, isDark),
        const SizedBox(width: 8),
        _statCard(Icons.star, rating.toStringAsFixed(1), 'Rating', AppColors.orange, isDark),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grayDark : AppColors.grayLight,
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

  Widget _metricCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grayDark : AppColors.white,
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

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
