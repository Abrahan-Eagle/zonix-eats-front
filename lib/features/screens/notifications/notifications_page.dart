import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      // No marcar todo como leído al abrir: el badge de la campanita depende de _unreadCount.
    });
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      await context.read<NotificationService>().markAllAsRead();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas las notificaciones marcadas como leídas')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
    }
  }

  Future<void> _loadNotifications() async {
    await context.read<NotificationService>().loadInitialData();
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
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            icon: Icon(Icons.done_all, color: onSurface),
            onPressed: () => _markAllAsRead(context),
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final list = notificationService.items;

          if (notificationService.isLoading && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationService.error != null && list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(notificationService.error!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => notificationService.loadInitialData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (list.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slateBorder : AppColors.stitchBorder.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Todo al día',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tienes notificaciones pendientes por ahora. Te avisaremos cuando ocurra algo importante.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: _loadNotifications,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Refrescar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final groups = _groupByDate(list);
          final order = _sectionOrder(groups);

          return RefreshIndicator(
            onRefresh: _loadNotifications,
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
                          onTap: () {
                            notificationService.navigateToNotificationDetail(context, n);
                          },
                          onDelete: n.id == null
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar notificación'),
                                      content: const Text('¿Quitar esta notificación de la lista?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true || !context.mounted) return;
                                  try {
                                    await notificationService.deleteNotification(n.id!);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Notificación eliminada')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
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
  final Future<void> Function()? onDelete;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.timeLabel,
    this.onTap,
    this.onDelete,
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
          padding: const EdgeInsets.only(left: 16, right: 4, top: 16, bottom: 16),
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
              if (onDelete != null)
                IconButton(
                  tooltip: 'Eliminar',
                  icon: Icon(Icons.close, color: onSurfaceVariant, size: 22),
                  onPressed: () => onDelete!(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
