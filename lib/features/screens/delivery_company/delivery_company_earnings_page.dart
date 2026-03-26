import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_company_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';

class DeliveryCompanyEarningsPage extends StatefulWidget {
  const DeliveryCompanyEarningsPage({super.key});

  @override
  State<DeliveryCompanyEarningsPage> createState() => _DeliveryCompanyEarningsPageState();
}

class _DeliveryCompanyEarningsPageState extends State<DeliveryCompanyEarningsPage> {
  String _selectedPeriod = 'Esta semana';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryCompanyService>().loadEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, service, _) {
          if (service.earningsLoading && service.earningsData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (service.earningsError != null && service.earningsData.isEmpty) {
            return _buildError(service.earningsError!, () => service.loadEarnings());
          }

          final data = service.earningsData;
          final todayEarnings = _num(data['today_earnings']);
          final weekEarnings = _num(data['week_earnings']);
          final monthEarnings = _num(data['month_earnings']);
          final totalEarnings = _num(data['total_earnings']);
          final breakdown = (data['agents_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          double highlighted;
          switch (_selectedPeriod) {
            case 'Hoy':
              highlighted = todayEarnings;
              break;
            case 'Esta semana':
              highlighted = weekEarnings;
              break;
            case 'Este mes':
              highlighted = monthEarnings;
              break;
            default:
              highlighted = totalEarnings;
          }

          return RefreshIndicator(
            onRefresh: () => service.loadEarnings(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodChips(isDark),
                const SizedBox(height: 16),
                _buildMainEarnings(highlighted, isDark),
                const SizedBox(height: 16),
                _buildSummaryRow(todayEarnings, weekEarnings, monthEarnings, totalEarnings, isDark),
                const SizedBox(height: 20),
                _buildSectionTitle('Desglose por agente'),
                const SizedBox(height: 12),
                if (breakdown.isEmpty)
                  _buildEmpty()
                else
                  ...breakdown.map((a) => _buildAgentRow(a, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodChips(bool isDark) {
    const periods = ['Hoy', 'Esta semana', 'Este mes'];
    return Wrap(
      spacing: 8,
      children: periods.map((p) {
        final selected = _selectedPeriod == p;
        return ChoiceChip(
          label: Text(p),
          selected: selected,
          selectedColor: AppColors.orange.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: selected ? AppColors.orange : (isDark ? AppColors.white70 : AppColors.gray),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) => setState(() => _selectedPeriod = p),
        );
      }).toList(),
    );
  }

  Widget _buildMainEarnings(double amount, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.orange, AppColors.orangeCoral]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(_selectedPeriod, style: const TextStyle(color: AppColors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double today, double week, double month, double total, bool isDark) {
    return Row(
      children: [
        _smallCard('Hoy', today, AppColors.green, isDark),
        const SizedBox(width: 6),
        _smallCard('Semana', week, AppColors.blue, isDark),
        const SizedBox(width: 6),
        _smallCard('Mes', month, AppColors.purple, isDark),
        const SizedBox(width: 6),
        _smallCard('Total', total, AppColors.orange, isDark),
      ],
    );
  }

  Widget _smallCard(String label, double value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grayDark : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.secondaryText(context))),
            const SizedBox(height: 2),
            Text('\$${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentRow(Map<String, dynamic> agent, bool isDark) {
    final name = agent['name'] as String? ?? 'Agente';
    final deliveries = safeInt(agent['deliveries']);
    final earnings = _num(agent['earnings']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.white12 : AppColors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.blue.withValues(alpha: 0.15),
            child: const Icon(Icons.person, color: AppColors.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$deliveries entregas', style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
              ],
            ),
          ),
          Text(
            '\$${earnings.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText(context)));
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text('Sin datos de agentes', style: TextStyle(color: AppColors.secondaryText(context))),
      ),
    );
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
