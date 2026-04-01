import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';
import '../../utils/responsive_helper.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _revenue = {};
  Map<String, dynamic> _orders = {};
  Map<String, dynamic> _kpi = {};
  Map<String, dynamic> _deliveryObs = {};
  List<Map<String, dynamic>> _deliveryIncidents = [];
  List<Map<String, dynamic>> _deliveryHistory = [];
  List<Map<String, dynamic>> _deliveryRunbooks = [];
  String? _incidentTypeFilter;
  int _obsWindowHours = 24;
  bool _isLoading = true;
  String? _error;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = context.read<AdminService>();

    try {
      final results = await Future.wait([
        service.getAnalyticsOverview(),
        service.getAnalyticsRevenue(),
        service.getAnalyticsOrders(),
        service.getAnalyticsKpi(),
        service.getDeliveryObservabilitySummary(windowHours: _obsWindowHours),
        service.getDeliveryObservabilityIncidents(
          type: _incidentTypeFilter,
          windowHours: _obsWindowHours,
        ),
        service.getDeliveryObservabilityHistory(
          perPage: 12,
          windowHours: _obsWindowHours,
        ),
        service.getDeliveryObservabilityRunbooks(),
      ]);

      if (!mounted) return;
      setState(() {
        _overview = results[0];
        _revenue = results[1];
        _orders = results[2];
        _kpi = results[3];
        _deliveryObs = results[4];
        final incidentsPayload = results[5]['data'];
        if (incidentsPayload is Map && incidentsPayload['items'] is List) {
          _deliveryIncidents =
              List<Map<String, dynamic>>.from(incidentsPayload['items']);
        } else {
          _deliveryIncidents = [];
        }
        final historyPayload = results[6]['data'];
        _deliveryHistory = (historyPayload is Map && historyPayload['items'] is List)
            ? List<Map<String, dynamic>>.from(historyPayload['items'])
            : [];
        final runbooksPayload = results[7]['data'];
        _deliveryRunbooks = (runbooksPayload is Map && runbooksPayload['items'] is List)
            ? List<Map<String, dynamic>>.from(runbooksPayload['items'])
            : [];
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Analíticas'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) return _buildErrorState();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: ResponsiveCenter(
          maxWidth: 1200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Resumen'),
              const SizedBox(height: 12),
              _buildOverviewGrid(),
              const SizedBox(height: 28),
              _sectionTitle('Ingresos'),
              const SizedBox(height: 12),
              _buildRevenueSection(),
              const SizedBox(height: 28),
              _sectionTitle('Órdenes'),
              const SizedBox(height: 12),
              _buildOrdersSection(),
              const SizedBox(height: 28),
              _sectionTitle('KPIs'),
              const SizedBox(height: 12),
              _buildKpiSection(),
              const SizedBox(height: 28),
              _sectionTitle('Observabilidad Delivery'),
              const SizedBox(height: 12),
              _buildDeliveryObservabilitySection(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Overview Grid ────────────────────────────

  Widget _buildOverviewGrid() {
    final data = _overview['data'] is Map ? _overview['data'] : _overview;

    final items = <_OverviewItem>[
      _OverviewItem(
        Icons.receipt_long_rounded,
        '${safeInt(data['total_orders'])}',
        'Órdenes totales',
        AppColors.blue,
      ),
      _OverviewItem(
        Icons.payments_rounded,
        _shortCurrency(safeDouble(data['total_revenue'])),
        'Ingresos totales',
        AppColors.green,
      ),
      _OverviewItem(
        Icons.people_alt_rounded,
        '${safeInt(data['total_customers'])}',
        'Clientes',
        AppColors.orange,
      ),
      _OverviewItem(
        Icons.shopping_bag_rounded,
        _shortCurrency(safeDouble(data['average_order_value'])),
        'Ticket promedio',
        AppColors.purple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = Responsive.gridColumns(constraints.maxWidth, mobile: 2, tablet: 3, desktop: 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, i) => _overviewCard(items[i]),
        );
      },
    );
  }

  Widget _overviewCard(_OverviewItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!_isDark)
            const BoxShadow(
              color: AppColors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
        border: _isDark ? Border.all(color: AppColors.white12) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withAlpha(31),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: AppColors.secondaryText(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Revenue Section ──────────────────────────

  Widget _buildRevenueSection() {
    final data = _revenue['data'] is Map ? _revenue['data'] : _revenue;
    final daily = data['daily'] is List ? data['daily'] as List : [];
    final monthly = data['monthly'] is List ? data['monthly'] as List : [];

    if (daily.isEmpty && monthly.isEmpty) {
      return _emptyCard('Sin datos de ingresos disponibles');
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (daily.isNotEmpty) ...[
            _subsectionTitle('Ingresos diarios'),
            const SizedBox(height: 8),
            for (final d in daily.take(7))
              _revenueRow(
                safeString(d is Map ? d['date'] : ''),
                safeDouble(d is Map ? d['total'] ?? d['revenue'] : 0),
              ),
          ],
          if (daily.isNotEmpty && monthly.isNotEmpty)
            const Divider(height: 24),
          if (monthly.isNotEmpty) ...[
            _subsectionTitle('Ingresos mensuales'),
            const SizedBox(height: 8),
            for (final m in monthly.take(6))
              _revenueRow(
                safeString(m is Map ? m['month'] ?? m['date'] : ''),
                safeDouble(m is Map ? m['total'] ?? m['revenue'] : 0),
              ),
          ],
        ],
      ),
    );
  }

  Widget _revenueRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText(context),
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Orders Section ───────────────────────────

  Widget _buildOrdersSection() {
    final data = _orders['data'] is Map ? _orders['data'] : _orders;
    final statusDist = data['status_distribution'];
    final peakHours = data['peak_hours'];

    if (statusDist == null && peakHours == null) {
      return _emptyCard('Sin datos de órdenes disponibles');
    }

    return Column(
      children: [
        if (statusDist != null) _buildStatusDistribution(statusDist),
        if (statusDist != null && peakHours != null) const SizedBox(height: 16),
        if (peakHours != null) _buildPeakHours(peakHours),
      ],
    );
  }

  Widget _buildStatusDistribution(dynamic statusDist) {
    final Map<String, int> statuses = {};
    if (statusDist is Map) {
      for (final entry in statusDist.entries) {
        statuses[safeString(entry.key)] = safeInt(entry.value);
      }
    } else if (statusDist is List) {
      for (final item in statusDist) {
        if (item is Map) {
          statuses[safeString(item['status'])] = safeInt(item['count']);
        }
      }
    }

    if (statuses.isEmpty) return const SizedBox.shrink();

    final total = statuses.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subsectionTitle('Distribución por estado'),
          const SizedBox(height: 12),
          for (final entry in statuses.entries) ...[
            _statusBar(entry.key, entry.value, total),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _statusBar(String status, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;
    final color = _statusColor(status);
    final label = _statusLabel(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText(context),
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${(pct * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: _isDark ? AppColors.white12 : AppColors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPeakHours(dynamic peakHours) {
    final List<Map<String, dynamic>> hours = [];
    if (peakHours is List) {
      for (final h in peakHours) {
        if (h is Map) hours.add(Map<String, dynamic>.from(h));
      }
    } else if (peakHours is Map) {
      for (final entry in peakHours.entries) {
        hours.add({'hour': entry.key, 'count': entry.value});
      }
    }

    if (hours.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subsectionTitle('Horas pico'),
          const SizedBox(height: 10),
          for (final h in hours.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 16, color: AppColors.secondaryText(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${safeString(h['hour'])}h',
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${safeInt(h['count'])} órdenes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────── KPI Section ─────────────────────────────

  Widget _buildKpiSection() {
    final data = _kpi['data'] is Map ? _kpi['data'] : _kpi;
    final financial = data['financial'];
    final operational = data['operational'];
    final customer = data['customer'];

    if (financial == null && operational == null && customer == null) {
      return _emptyCard('Sin datos de KPI disponibles');
    }

    return Column(
      children: [
        if (financial is Map)
          _kpiGroup('Financieros', Icons.attach_money_rounded,
              AppColors.green, financial),
        if (financial is Map) const SizedBox(height: 16),
        if (operational is Map)
          _kpiGroup('Operacionales', Icons.settings_rounded,
              AppColors.blue, operational),
        if (operational is Map) const SizedBox(height: 16),
        if (customer is Map)
          _kpiGroup('Clientes', Icons.people_alt_rounded, AppColors.orange,
              customer),
      ],
    );
  }

  Widget _buildDeliveryObservabilitySection() {
    final data = _deliveryObs['data'] is Map ? _deliveryObs['data'] : _deliveryObs;
    final kpi = data['kpi'] is Map ? data['kpi'] as Map : {};
    final ordersTotal = safeInt(kpi['orders_total']);
    final unassigned = safeInt(kpi['unassigned_over_threshold']);
    final frozen = safeInt(kpi['frozen_tracking_count']);
    final timeoutRatio = safeDouble(kpi['timeout_ratio_percent']);
    final avgAssign = safeDouble(kpi['avg_assignment_minutes']);
    final avgDelivery = safeDouble(kpi['avg_delivery_minutes']);
    final noResponse = safeDouble(kpi['agent_no_response_ratio_percent']);
    final successRatio = safeDouble(kpi['success_ratio_percent']);
    final cancelledRatio = safeDouble(kpi['cancelled_ratio_percent']);

    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subsectionTitle('SLA delivery'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('24h'),
                    selected: _obsWindowHours == 24,
                    onSelected: (_) {
                      setState(() => _obsWindowHours = 24);
                      _loadData();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('12h'),
                    selected: _obsWindowHours == 12,
                    onSelected: (_) {
                      setState(() => _obsWindowHours = 12);
                      _loadData();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('6h'),
                    selected: _obsWindowHours == 6,
                    onSelected: (_) {
                      setState(() => _obsWindowHours = 6);
                      _loadData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _obsChip('Órdenes (ventana)', '$ordersTotal'),
                  _obsChip('Sin asignar', '$unassigned'),
                  _obsChip('Tracking congelado', '$frozen'),
                  _obsChip('Timeout %', '${timeoutRatio.toStringAsFixed(2)}%'),
                  _obsChip('Asignación promedio', '${avgAssign.toStringAsFixed(2)} min'),
                  _obsChip('Entrega promedio', '${avgDelivery.toStringAsFixed(2)} min'),
                  _obsChip('No respuesta agente', '${noResponse.toStringAsFixed(2)}%'),
                  _obsChip('Éxito', '${successRatio.toStringAsFixed(2)}%'),
                  _obsChip('Canceladas', '${cancelledRatio.toStringAsFixed(2)}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subsectionTitle('Incidentes activos'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _incidentTypeFilter == null,
                    onSelected: (_) {
                      setState(() => _incidentTypeFilter = null);
                      _loadData();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Sin asignar'),
                    selected: _incidentTypeFilter == 'unassigned_order',
                    onSelected: (_) {
                      setState(() => _incidentTypeFilter = 'unassigned_order');
                      _loadData();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Tracking congelado'),
                    selected: _incidentTypeFilter == 'frozen_tracking',
                    onSelected: (_) {
                      setState(() => _incidentTypeFilter = 'frozen_tracking');
                      _loadData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_deliveryIncidents.isEmpty)
                Text(
                  'No hay incidentes activos.',
                  style: TextStyle(color: AppColors.secondaryText(context)),
                )
              else
                for (final incident in _deliveryIncidents.take(12))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          safeString(incident['priority']) == 'high'
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline_rounded,
                          color: safeString(incident['priority']) == 'high'
                              ? AppColors.red
                              : AppColors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${safeString(incident['event_code'])} · orden #${safeInt(incident['order_id'])}',
                            style: TextStyle(color: AppColors.primaryText(context)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openIncidentOrders(safeString(incident['type'])),
                          child: const Text('Ver órdenes'),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subsectionTitle('Historico reciente (snapshots)'),
              const SizedBox(height: 8),
              if (_deliveryHistory.isEmpty)
                Text(
                  'Sin snapshots historicos.',
                  style: TextStyle(color: AppColors.secondaryText(context)),
                )
              else
                for (final snapshot in _deliveryHistory.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '• ${safeString(snapshot['created_at'])} · TTA ${safeDouble(snapshot['avg_assignment_minutes']).toStringAsFixed(2)}m · TTD ${safeDouble(snapshot['avg_delivery_minutes']).toStringAsFixed(2)}m',
                      style: TextStyle(color: AppColors.primaryText(context), fontSize: 12),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subsectionTitle('Runbooks operativos'),
              const SizedBox(height: 8),
              if (_deliveryRunbooks.isEmpty)
                Text(
                  'Sin runbooks disponibles.',
                  style: TextStyle(color: AppColors.secondaryText(context)),
                )
              else
                for (final rb in _deliveryRunbooks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '• ${safeString(rb['title'])} (${safeString(rb['severity'])})',
                      style: TextStyle(color: AppColors.primaryText(context), fontSize: 12),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _obsChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.grayDark : AppColors.grayLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isDark ? AppColors.white12 : AppColors.black12),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppColors.primaryText(context), fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _kpiGroup(
      String title, IconData icon, Color color, Map kpiMap) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              _subsectionTitle(title),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in kpiMap.entries)
            _kpiRow(
              _humanizeKey(safeString(entry.key)),
              _formatKpiValue(entry.value),
            ),
        ],
      ),
    );
  }

  Widget _kpiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.primaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Shared widgets ──────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText(context),
      ),
    );
  }

  Widget _subsectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText(context),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!_isDark)
            const BoxShadow(
              color: AppColors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
        border: _isDark ? Border.all(color: AppColors.white12) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: _isDark ? Border.all(color: AppColors.white12) : null,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.secondaryText(context)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Helpers ─────────────────────────────────

  String _shortCurrency(double amount) {
    if (amount >= 1000000) return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(1)}K';
    return '\$${amount.toStringAsFixed(2)}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return AppColors.orange;
      case 'paid':
        return AppColors.blue;
      case 'processing':
      case 'preparing':
        return AppColors.teal;
      case 'shipped':
      case 'out_for_delivery':
        return AppColors.purple;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.stitchSlate;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Pendiente de pago';
      case 'paid':
        return 'Pagado';
      case 'processing':
        return 'Procesando';
      case 'preparing':
        return 'Preparando';
      case 'shipped':
        return 'Enviado';
      case 'out_for_delivery':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String _humanizeKey(String key) {
    return key.replaceAll('_', ' ').replaceFirstMapped(
        RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
  }

  String _formatKpiValue(dynamic value) {
    if (value is num) {
      if (value == value.toInt()) return '${value.toInt()}';
      return value.toStringAsFixed(2);
    }
    return safeString(value, '—');
  }

  Future<void> _openIncidentOrders(String type) async {
    final service = context.read<AdminService>();
    try {
      final response = await service.getDeliveryObservabilityIncidentOrders(
        type: type,
        windowHours: _obsWindowHours,
        perPage: 30,
      );
      final payload = response['data'];
      final items = (payload is Map && payload['items'] is List)
          ? List<Map<String, dynamic>>.from(payload['items'])
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: items.isEmpty
                ? const Center(child: Text('No hay órdenes para este incidente'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final order = items[i];
                      final commerce = order['commerce'] is Map ? order['commerce'] as Map : {};
                      return ListTile(
                        title: Text('Orden #${safeInt(order['id'])}'),
                        subtitle: Text('${safeString(order['status'])} · ${safeString(commerce['business_name'])}'),
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (_) {}
  }
}

// ──────────────────────── Data holders ───────────────────────────────

class _OverviewItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _OverviewItem(this.icon, this.value, this.label, this.color);
}
