import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/models/order.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  String _selectedPeriod = 'Todo';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (_selectedPeriod) {
      case 'Hoy':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Esta semana':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'Este mes':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Todo':
        break;
    }

    if (!mounted) return;
    final d = context.read<DeliveryService>();
    await d.loadHistory(startDate: start, endDate: end);
    if (!mounted) return;
    await syncDeliverySessionAfterApi(context, d);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de entregas')),
      body: Consumer<DeliveryService>(
        builder: (context, service, _) {
          if (service.historyLoading && service.historyOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (service.historyError != null && service.historyOrders.isEmpty) {
            return _buildErrorState(service.historyError!);
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodChips(isDark),
                const SizedBox(height: 16),
                _buildSummaryRow(service.historyOrders, isDark),
                const SizedBox(height: 20),
                if (service.historyOrders.isEmpty)
                  _buildEmptyState()
                else
                  ...service.historyOrders.map((o) => _buildOrderCard(o, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodChips(bool isDark) {
    const periods = ['Hoy', 'Esta semana', 'Este mes', 'Todo'];
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

  Widget _buildSummaryRow(List<Order> orders, bool isDark) {
    final total = orders.length;
    final delivered = orders.where((o) => o.status == 'delivered').length;
    final cancelled = orders.where((o) => o.status == 'cancelled').length;

    return Row(
      children: [
        _summaryTile('Total', '$total', AppColors.orange, isDark),
        const SizedBox(width: 8),
        _summaryTile('Completadas', '$delivered', AppColors.green, isDark),
        const SizedBox(width: 8),
        _summaryTile('Canceladas', '$cancelled', AppColors.red, isDark),
      ],
    );
  }

  Widget _summaryTile(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grayDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isDark) {
    final isDelivered = order.status == 'delivered';
    final statusColor = isDelivered ? AppColors.green : AppColors.red;
    final statusLabel = isDelivered ? 'Entregada' : 'Cancelada';
    final commerceName = order.commerce?['name']?.toString() ?? 'Comercio';
    final date = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.grayDark : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDelivered ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Orden #${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.store, size: 16, color: AppColors.secondaryText(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    commerceName,
                    style: TextStyle(color: AppColors.secondaryText(context), fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.secondaryText(context)),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(color: AppColors.secondaryText(context), fontSize: 13),
                ),
                const Spacer(),
                if (isDelivered)
                  Text(
                    '\$${order.deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: AppColors.secondaryText(context)),
          const SizedBox(height: 16),
          Text(
            'No hay entregas en este período',
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
