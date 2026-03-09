import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/models/notification_item.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Agrupa notificaciones por "Hoy", "Ayer" o fecha formateada.
Map<String, List<NotificationItem>> _groupByDate(List<NotificationItem> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final Map<String, List<NotificationItem>> groups = {};

  for (final n in items) {
    final d = DateTime(n.receivedAt.year, n.receivedAt.month, n.receivedAt.day);
    String key;
    if (d == today) {
      key = 'Hoy';
    } else if (d == yesterday) {
      key = 'Ayer';
    } else {
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      key = '${n.receivedAt.day} ${months[n.receivedAt.month - 1]}';
    }
    groups.putIfAbsent(key, () => []).add(n);
  }
  return groups;
}

/// Orden de secciones: Hoy primero, luego Ayer, luego fechas antiguas.
List<String> _sectionOrder(Map<String, List<NotificationItem>> groups) {
  final keys = groups.keys.toList();
  final ordered = <String>[];
  if (keys.contains('Hoy')) ordered.add('Hoy');
  if (keys.contains('Ayer')) ordered.add('Ayer');
  for (final k in keys) {
    if (k != 'Hoy' && k != 'Ayer') ordered.add(k);
  }
  ordered.sort((a, b) {
    if (a == 'Hoy') return -1;
    if (b == 'Hoy') return 1;
    if (a == 'Ayer') return -1;
    if (b == 'Ayer') return 1;
    return 0;
  });
  return ordered.isEmpty ? keys : ordered;
}

/// Icono y color según tipo de notificación (template: order, promo, points, support).
({IconData icon, Color bgColor, Color iconColor}) _styleForType(String? type, BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final mutedBg = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
  final mutedFg = isDark ? AppColors.stitchSlate400 : AppColors.textMutedGray;

  switch (type?.toLowerCase()) {
    case 'order':
    case 'pedido':
      return (icon: Icons.shopping_bag_outlined, bgColor: AppColors.blue.withValues(alpha: 0.2), iconColor: AppColors.blue);
    case 'promotion':
    case 'promoción':
    case 'promo':
      return (icon: Icons.local_offer_outlined, bgColor: AppColors.amber.withValues(alpha: 0.2), iconColor: AppColors.amber);
    case 'points':
    case 'puntos':
    case 'loyalty':
      return (icon: Icons.star_outline, bgColor: AppColors.green.withValues(alpha: 0.2), iconColor: AppColors.green);
    case 'support':
    case 'soporte':
    case 'consulta':
      return (icon: Icons.support_agent_outlined, bgColor: mutedBg, iconColor: mutedFg);
    default:
      break;
  }
  return (icon: Icons.check_circle_outline, bgColor: mutedBg, iconColor: mutedFg);
}

/// Inferir tipo desde título/cuerpo cuando el backend no envía type.
String? _inferType(NotificationItem n) {
  final t = n.title.toLowerCase();
  final b = n.body.toLowerCase();
  if (t.contains('pedido') || t.contains('entregado') || t.contains('confirmado') || b.contains('pedido')) return 'order';
  if (t.contains('promo') || t.contains('descuento') || t.contains('oferta') || t.contains('% off')) return 'promotion';
  if (t.contains('puntos') || t.contains('points') || b.contains('puntos') || b.contains('points')) return 'points';
  if (t.contains('soporte') || t.contains('consulta') || t.contains('resuelta') || b.contains('solicitud')) return 'support';
  return null;
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<NotificationItem>> _notificationsFuture;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationService.markAllAsRead();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _notificationService.getNotificationItems();
    });
  }

  String _formatTime(NotificationItem n) {
    final now = DateTime.now();
    final d = n.receivedAt;
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notifDay = DateTime(d.year, d.month, d.day);
    if (notifDay == today) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (notifDay == yesterday) return 'Ayer';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    const sectionTodayColor = AppColors.blue;
    final sectionOtherColor = onSurfaceVariant;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: onSurface, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Notificaciones',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No hay notificaciones',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final groups = _groupByDate(list);
          final order = _sectionOrder(groups);

          return RefreshIndicator(
            onRefresh: () async {
              _loadNotifications();
              await _notificationsFuture;
            },
            color: sectionTodayColor,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (int s = 0; s < order.length; s++) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      top: s == 0 ? 24 : 32,
                      bottom: 12,
                    ),
                    child: Text(
                      order[s].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: order[s] == 'Hoy' ? sectionTodayColor : sectionOtherColor,
                      ),
                    ),
                  ),
                  for (final n in groups[order[s]]!) ...[
                    Builder(
                      builder: (context) {
                        final effectiveType = n.type ?? _inferType(n);
                        final style = _styleForType(effectiveType, context);
                        return _NotificationTile(
                          notification: n,
                          icon: style.icon,
                          iconBgColor: style.bgColor,
                          iconColor: style.iconColor,
                          timeLabel: _formatTime(n),
                          onTap: () async {
                            if (n.id != null) {
                              await _notificationService.markAsRead(n.id!);
                              _loadNotifications();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String timeLabel;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.timeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: onSurfaceVariant,
                          ),
                        ),
                        if (notification.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
