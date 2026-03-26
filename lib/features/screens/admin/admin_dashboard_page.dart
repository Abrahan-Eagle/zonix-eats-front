import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/admin_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';
import 'package:zonix/features/screens/admin/admin_users_page.dart';
import 'package:zonix/features/screens/admin/admin_analytics_page.dart';
import 'package:zonix/features/screens/admin/admin_commerces_page.dart';
import 'package:zonix/features/screens/admin/admin_orders_page.dart';
import 'package:zonix/features/screens/admin/admin_delivery_config_page.dart';
import 'package:zonix/features/screens/admin/admin_disputes_page.dart';
import 'package:zonix/features/screens/admin/admin_delivery_companies_page.dart';
import 'package:zonix/features/screens/admin/admin_notifications_page.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _realtime = {};
  Map<String, dynamic> _health = {};
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
        service.getSystemStatistics(),
        service.getSystemHealth(),
      ]);

      Map<String, dynamic> realtimeData = {};
      try {
        realtimeData = await service.getAnalyticsRealtime();
      } catch (_) {
        // Realtime endpoint may not be available yet
      }

      if (!mounted) return;
      setState(() {
        _stats = results[0];
        _health = results[1];
        _realtime = realtimeData;
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

  // ──────────────────────────── Build ────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: false,
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
          Consumer<NotificationService>(
            builder: (context, ns, _) => IconButton(
              icon: Badge(
                label: Text(ns.unreadCount.toString()),
                isLabelVisible: ns.unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthBanner(),
            const SizedBox(height: 24),
            _sectionTitle('Métricas'),
            const SizedBox(height: 12),
            _buildMetricsGrid(),
            const SizedBox(height: 28),
            _sectionTitle('Acciones rápidas'),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _sectionTitle('Distribución por rol'),
            const SizedBox(height: 12),
            _buildRoleDistribution(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Health Banner ─────────────────────────

  Widget _buildHealthBanner() {
    final status = safeString(_health['server_status'], 'unknown');
    final isHealthy = status == 'healthy';
    final score = safeInt(_health['performance_score']);

    final Color startColor = isHealthy
        ? (_isDark ? const Color(0xFF0D4A2E) : AppColors.greenLight100)
        : (_isDark ? const Color(0xFF4A0D0D) : const Color(0xFFFEE2E2));
    final Color endColor = isHealthy
        ? (_isDark ? const Color(0xFF064E3B) : const Color(0xFFA7F3D0))
        : (_isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5));
    final Color accentColor = isHealthy ? AppColors.green : AppColors.red;
    final Color textColor =
        _isDark ? AppColors.white : AppColors.blueDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startColor, endColor]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'Sistema saludable' : 'Sistema con problemas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uptime ${safeString(_health['uptime'], 'N/A')}  •  '
                  'Resp. ${safeString(_health['response_time'], 'N/A')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
          if (score > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$score%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────── Metrics Grid ─────────────────────────

  Widget _buildMetricsGrid() {
    final totalUsers = safeInt(_stats['total_users']);
    final ordersToday = safeInt(
      _realtime['orders_today'] ?? _stats['total_orders'],
    );
    final revenueToday = safeDouble(
      _realtime['revenue_today'] ?? _stats['total_revenue'],
    );
    final activeCommerces = safeInt(_stats['total_commerces']);

    final distMap = _stats['user_distribution'];
    final activeDelivery = safeInt(
      _realtime['active_deliveries'] ??
          (distMap is Map ? distMap['delivery'] : null),
    );
    final avgWait = _realtime.containsKey('avg_delivery_time')
        ? safeString(_realtime['avg_delivery_time'], 'N/A')
        : 'N/A';

    final metrics = <_Metric>[
      _Metric(Icons.people_alt_rounded, '$totalUsers', 'Total usuarios',
          AppColors.blue),
      _Metric(Icons.receipt_long_rounded, '$ordersToday', 'Órdenes hoy',
          AppColors.orange),
      _Metric(Icons.payments_rounded, _shortCurrency(revenueToday),
          'Ingresos hoy', AppColors.green),
      _Metric(Icons.storefront_rounded, '$activeCommerces', 'Comercios',
          AppColors.purple),
      _Metric(Icons.delivery_dining_rounded, '$activeDelivery',
          'Delivery activos', AppColors.teal),
      _Metric(Icons.timer_rounded, avgWait, 'Espera prom.', AppColors.amber),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Celdas más altas que anchas: evita overflow del Column en pantallas estrechas
        childAspectRatio: 0.68,
      ),
      itemBuilder: (_, i) => _metricCard(metrics[i]),
    );
  }

  Widget _metricCard(_Metric m) {
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: m.color.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              m.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: Text(
                m.label,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  color: AppColors.secondaryText(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Quick Actions ─────────────────────────

  Widget _buildQuickActions() {
    final actions = <_QuickAction>[
      _QuickAction(
          'Usuarios', Icons.people_alt_rounded, AppColors.blue, _goUsers),
      _QuickAction(
          'Comercios', Icons.storefront_rounded, AppColors.orange, _goCommerces),
      _QuickAction(
          'Órdenes', Icons.receipt_long_rounded, AppColors.green, _goOrders),
      _QuickAction('Config Delivery', Icons.delivery_dining_rounded,
          AppColors.purple, _goDeliveryConfig),
      _QuickAction(
          'Analytics', Icons.analytics_rounded, AppColors.teal, _goAnalytics),
      _QuickAction(
          'Disputas', Icons.gavel_rounded, AppColors.red, _goDisputes),
      _QuickAction('Empresas Delivery', Icons.local_shipping_rounded,
          AppColors.orangeCoral, _goDeliveryCompanies),
      _QuickAction('Notificaciones', Icons.notifications_active_rounded,
          AppColors.green, _goNotifications),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) => _quickActionCard(actions[i]),
    );
  }

  Widget _quickActionCard(_QuickAction a) {
    return Material(
      color: AppColors.cardBg(context),
      borderRadius: BorderRadius.circular(16),
      elevation: _isDark ? 0 : 2,
      child: InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: _isDark
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white12),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: a.color.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, color: a.color, size: 22),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Text(
                    a.label,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────── Role Distribution ───────────────────────

  Widget _buildRoleDistribution() {
    final dist = _stats['user_distribution'];
    if (dist == null || dist is! Map) {
      return _emptyCard('Sin datos de distribución');
    }

    final total = safeInt(_stats['total_users'], 1);
    final roles = <_RoleEntry>[
      _RoleEntry('Compradores', safeInt(dist['buyers']), AppColors.blue),
      _RoleEntry('Comercios', safeInt(dist['commerce']), AppColors.orange),
      _RoleEntry('Delivery', safeInt(dist['delivery']), AppColors.green),
      _RoleEntry(
          'Emp. Delivery', safeInt(dist['delivery_company']), AppColors.purple),
      _RoleEntry('Administradores', safeInt(dist['admin']), AppColors.red),
    ];

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < roles.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _roleBar(roles[i], total),
          ],
        ],
      ),
    );
  }

  Widget _roleBar(_RoleEntry role, int total) {
    final pct = total > 0 ? role.count / total : 0.0;
    final pctLabel = '${(pct * 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: role.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                role.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText(context),
                ),
              ),
            ),
            Text(
              '${role.count}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($pctLabel)',
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
            valueColor: AlwaysStoppedAnimation<Color>(role.color),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────── Helpers ───────────────────────────

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

  String _shortCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  // ──────────────────────── Navigation ────────────────────────────

  void _goUsers() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminUsersPage()),
      );

  void _goAnalytics() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminAnalyticsPage()));

  void _goCommerces() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminCommercesPage()));

  void _goOrders() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminOrdersPage()));

  void _goDeliveryConfig() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminDeliveryConfigPage()));

  void _goDisputes() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminDisputesPage()));

  void _goDeliveryCompanies() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminDeliveryCompaniesPage()));

  void _goNotifications() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminNotificationsPage()));
}

// ────────────────────────── Data holders ──────────────────────────

class _Metric {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Metric(this.icon, this.value, this.label, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _RoleEntry {
  final String label;
  final int count;
  final Color color;
  const _RoleEntry(this.label, this.count, this.color);
}
