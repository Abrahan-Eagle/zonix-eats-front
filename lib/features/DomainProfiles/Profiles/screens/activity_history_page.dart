/// Pantalla de Historial de Actividad.
///
/// Muestra actividades del usuario agrupadas por fecha (Hoy, Ayer, etc.)
/// con filtros por período: Hoy, Esta semana, Este mes.
/// Consume API /api/user/activity-history con parámetros de fecha.
library activity_history_page;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/services/activity_service.dart';

enum _PeriodFilter { today, week, month }

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  _PeriodFilter _selectedPeriod = _PeriodFilter.today;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  ({DateTime start, DateTime end}) _getRangeFor(_PeriodFilter period) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (period) {
      case _PeriodFilter.today:
        return (start: todayStart, end: now);
      case _PeriodFilter.week:
        final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        return (start: weekStart, end: now);
      case _PeriodFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return (start: monthStart, end: now);
    }
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final range = _getRangeFor(_selectedPeriod);
      final list = await ActivityService.getUserActivityHistory(
        startDate: range.start,
        endDate: range.end,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _activities = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _activities = [];
        });
      }
    }
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';
    return DateFormat('EEEE d MMM', 'es').format(date);
  }

  String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return DateFormat('HH:mm').format(date);
    if (d == yesterday) return 'Ayer';
    return DateFormat('d MMM', 'es').format(date);
  }

  Map<String, List<Map<String, dynamic>>> _groupByDay() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final a in _activities) {
      final createdAt = a['created_at'];
      DateTime date;
      try {
        date = createdAt != null ? DateTime.parse(createdAt.toString()) : DateTime.now();
      } catch (_) {
        date = DateTime.now();
      }
      final key = DateTime(date.year, date.month, date.day).toIso8601String();
      grouped.putIfAbsent(key, () => []).add(a);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final t1 = a['created_at']?.toString() ?? '';
        final t2 = b['created_at']?.toString() ?? '';
        return t2.compareTo(t1);
      });
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.grayDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.blueDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Historial de Actividad',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.blueDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterChips(context, isDark),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(isDark)
                    : _activities.isEmpty
                        ? _buildEmpty(isDark)
                        : _buildActivityList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppColors.grayDark : Colors.white,
      child: Row(
        children: [
          _chip('Hoy', _PeriodFilter.today, isDark),
          const SizedBox(width: 12),
          _chip('Esta semana', _PeriodFilter.week, isDark),
          const SizedBox(width: 12),
          _chip('Este mes', _PeriodFilter.month, isDark),
        ],
      ),
    );
  }

  Widget _chip(String label, _PeriodFilter period, bool isDark) {
    final selected = _selectedPeriod == period;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
          _loadActivity();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : (isDark ? AppColors.stitchSurfaceLighter : AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : (isDark ? AppColors.white70 : AppColors.gray),
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el historial',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.blueDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMutedGray),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadActivity,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.textMutedGray),
          const SizedBox(height: 16),
          Text(
            'No hay actividad en este período',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.white70 : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(bool isDark) {
    final grouped = _groupByDay();
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final date = DateTime.parse(key);
        final items = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                _sectionLabel(date),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.blueDark,
                ),
              ),
            ),
            ...items.map((a) => _buildActivityCard(context, a, isDark)),
            if (index < keys.length - 1) const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity, bool isDark) {
    final type = (activity['activity_type'] ?? activity['type'])?.toString() ?? 'unknown';
    final description = activity['description']?.toString() ?? '';
    final createdAt = activity['created_at']?.toString();
    DateTime date;
    try {
      date = createdAt != null ? DateTime.parse(createdAt) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }
    final title = _getActivityTitle(type);
    final iconData = _getActivityIcon(type);
    final color = _getActivityColor(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.stitchSurfaceLighter : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.white12 : AppColors.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(iconData, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.blueDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.white54 : AppColors.textMutedGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeLabel(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white54 : AppColors.textMutedGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityTitle(String type) {
    switch (type) {
      case 'order_placed':
      case 'order':
      case 'order_delivered':
        return 'Pedido Entregado';
      case 'order_cancelled':
        return 'Pedido Cancelado';
      case 'payment':
      case 'refund':
        return 'Reembolso Procesado';
      case 'profile_updated':
      case 'profile':
        return 'Perfil Actualizado';
      case 'review_posted':
      case 'review':
      case 'rating':
        return 'Calificación Recibida';
      case 'login':
        return 'Inicio de sesión';
      default:
        return 'Actividad';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order_placed':
      case 'order':
      case 'order_delivered':
        return Icons.shopping_cart;
      case 'order_cancelled':
        return Icons.cancel;
      case 'payment':
      case 'refund':
        return Icons.account_balance_wallet;
      case 'profile_updated':
      case 'profile':
        return Icons.person;
      case 'review_posted':
      case 'review':
      case 'rating':
        return Icons.star;
      case 'login':
        return Icons.login;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'order_placed':
      case 'order':
      case 'order_delivered':
        return AppColors.blue;
      case 'order_cancelled':
        return AppColors.red;
      case 'payment':
      case 'refund':
        return AppColors.green;
      case 'profile_updated':
      case 'profile':
        return AppColors.orange;
      case 'review_posted':
      case 'review':
      case 'rating':
        return AppColors.purple;
      case 'login':
        return AppColors.teal;
      default:
        return AppColors.textMutedGray;
    }
  }
}
