import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';

class DeliveryEarningsPage extends StatefulWidget {
  const DeliveryEarningsPage({super.key});

  @override
  State<DeliveryEarningsPage> createState() => _DeliveryEarningsPageState();
}

class _DeliveryEarningsPageState extends State<DeliveryEarningsPage> {
  String _selectedPeriod = 'Esta semana';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final d = context.read<DeliveryService>();
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (_selectedPeriod) {
      case 'Hoy':
        start = DateTime(now.year, now.month, now.day);
        end = now;
        break;
      case 'Esta semana':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = now;
        break;
      case 'Este mes':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
    }
    await d.loadEarnings(startDate: start, endDate: end);
    if (!mounted) return;
    await syncDeliverySessionAfterApi(context, d);
  }

  double _parseNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Laravel puede serializar DECIMAL como string en JSON; evita `.cast<num>()` que falla.
  int _parseIntLoose(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List<double> _parseFeeList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) {
      if (e is num) return e.toDouble();
      if (e is String) return double.tryParse(e) ?? 0.0;
      return 0.0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: Consumer<DeliveryService>(
        builder: (context, service, _) {
          if (service.earningsLoading && service.earningsMap.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (service.earningsError != null && service.earningsMap.isEmpty) {
            return _buildErrorState(service.earningsError!);
          }

          final data = service.earningsMap;
          final todayEarnings = _parseNum(data['today_earnings']);
          final weeklyEarnings = _parseNum(data['weekly_earnings']);
          final monthlyEarnings = _parseNum(data['monthly_earnings']);
          final totalEarnings = _parseNum(data['total_earnings']);
          final totalDeliveries = _parseIntLoose(data['total_deliveries']);
          final avgTime = _parseNum(data['average_delivery_time']);
          final fees = _parseFeeList(data['delivery_fees']);
          final dates = (data['delivery_dates'] as List?)?.cast<String>() ?? [];

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodChips(isDark),
                const SizedBox(height: 16),
                _buildSummaryCards(
                  isDark,
                  todayEarnings: todayEarnings,
                  weeklyEarnings: weeklyEarnings,
                  monthlyEarnings: monthlyEarnings,
                  totalEarnings: totalEarnings,
                ),
                const SizedBox(height: 16),
                _buildStatsRow(isDark, totalDeliveries, avgTime),
                const SizedBox(height: 20),
                if (fees.isEmpty)
                  _buildEmptyState()
                else
                  _buildRecentFees(isDark, fees, dates),
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
            color: selected
                ? AppColors.orange
                : (isDark ? AppColors.white70 : AppColors.gray),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) {
            setState(() => _selectedPeriod = p);
            _loadData();
          },
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(
    bool isDark, {
    required double todayEarnings,
    required double weeklyEarnings,
    required double monthlyEarnings,
    required double totalEarnings,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _earningsCard('Hoy', todayEarnings, AppColors.green, isDark,
                highlighted: _selectedPeriod == 'Hoy'),
            const SizedBox(width: 10),
            _earningsCard('Semana', weeklyEarnings, AppColors.blue, isDark,
                highlighted: _selectedPeriod == 'Esta semana'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _earningsCard('Mes', monthlyEarnings, AppColors.purple, isDark,
                highlighted: _selectedPeriod == 'Este mes'),
            const SizedBox(width: 10),
            _earningsCard('Total', totalEarnings, AppColors.orange, isDark),
          ],
        ),
      ],
    );
  }

  Widget _earningsCard(
    String label,
    double amount,
    Color color,
    bool isDark, {
    bool highlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grayDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted ? color : color.withValues(alpha: 0.25),
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, int deliveries, double avgTime) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grayDark : AppColors.grayLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining, color: AppColors.blue, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$deliveries',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Entregas',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grayDark : AppColors.grayLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.orange, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${avgTime.toStringAsFixed(0)} min',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Promedio',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFees(bool isDark, List<double> fees, List<String> dates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarifas recientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(fees.length, (i) {
          final fee = fees[i].toDouble();
          String dateStr = '';
          if (i < dates.length) {
            try {
              final dt = DateTime.parse(dates[i]);
              dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt);
            } catch (_) {
              dateStr = dates[i];
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grayDark : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.white12 : AppColors.black12,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrega #${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText(context),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${fee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.secondaryText(context)),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes ganancias registradas',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
