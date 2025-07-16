import 'package:flutter/material.dart';
import 'dart:async';
import '../../../features/services/commerce_notification_service.dart';
import '../../../features/services/commerce_data_service.dart';

class CommerceNotificationsPage extends StatefulWidget {
  const CommerceNotificationsPage({Key? key}) : super(key: key);

  @override
  State<CommerceNotificationsPage> createState() => _CommerceNotificationsPageState();
}

class _CommerceNotificationsPageState extends State<CommerceNotificationsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  StreamSubscription? _notificationsSubscription;
  List<Map<String, dynamic>> _notifications = [];
  int? _commerceId;

  final List<String> _typeTabs = [
    'Todas',
    'Órdenes',
    'Pagos',
    'Delivery',
    'Sistema',
  ];

  final Map<String, String> _typeFilters = {
    'Todas': '',
    'Órdenes': 'order',
    'Pagos': 'payment',
    'Delivery': 'delivery',
    'Sistema': 'system',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _typeTabs.length, vsync: this);
    _loadData();
    _initWebSocket();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationsSubscription?.cancel();
    CommerceNotificationService().dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _notificationsFuture = CommerceNotificationService().getNotifications(
        type: _typeFilters[_typeTabs[_tabController.index]],
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _statsFuture = CommerceNotificationService().getNotificationStats();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _loadData();
  }

  Future<void> _initWebSocket() async {
    try {
      final profile = await CommerceDataService.getCommerceProfile();
      _commerceId = profile['id'];
      
      await CommerceNotificationService().connectWebSocket(_commerceId!);
      
      // Escuchar actualizaciones en tiempo real
      _notificationsSubscription = CommerceNotificationService().notificationsStream?.listen((notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
          });
        }
      });
    } catch (e) {
      // Ignorar errores de conexión para no bloquear la vista
    }
  }

  Future<void> _markAsRead(int id) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceNotificationService().markAsRead(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación marcada como leída'),
          backgroundColor: Colors.green,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar como leída: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceNotificationService().markAllAsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          backgroundColor: Colors.green,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar todas como leídas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _deleteNotification(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceNotificationService().deleteNotification(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación eliminada'),
          backgroundColor: Colors.green,
        )
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar notificación: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resumen de Notificaciones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _loading ? null : _markAllAsRead,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Marcar todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['total_notifications'] ?? 0}',
                        Icons.notifications,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'No Leídas',
                        '${stats['unread_notifications'] ?? 0}',
                        Icons.mark_email_unread,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Hoy',
                        '${stats['today_notifications'] ?? 0}',
                        Icons.today,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Órdenes',
                        '${stats['order_notifications'] ?? 0}',
                        Icons.receipt,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Pagos',
                        '${stats['payment_notifications'] ?? 0}',
                        Icons.payment,
                        Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Delivery',
                        '${stats['delivery_notifications'] ?? 0}',
                        Icons.local_shipping,
                        Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar notificaciones',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() { _searchQuery = value; });
                _loadData();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ordenar por',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'created_at', child: Text('Fecha')),
                      DropdownMenuItem(value: 'title', child: Text('Título')),
                      DropdownMenuItem(value: 'type', child: Text('Tipo')),
                      DropdownMenuItem(value: 'read_at', child: Text('Estado')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortBy = value!; });
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Orden',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortOrder,
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Descendente')),
                      DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortOrder = value!; });
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read_at'] != null;
    final type = notification['type'] ?? 'system';
    final createdAt = DateTime.parse(notification['created_at'] ?? DateTime.now().toIso8601String());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(type),
          child: Icon(_getTypeIcon(type), color: Colors.white),
        ),
        title: Text(
          notification['title'] ?? 'Sin título',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['body'] ?? 'Sin contenido'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeText(type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isRead)
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _loading ? null : () => _markAsRead(notification['id']),
                    tooltip: 'Marcar como leída',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _loading ? null : () => _deleteNotification(notification['id']),
                  tooltip: 'Eliminar notificación',
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          // Aquí se podría abrir un detalle de la notificación
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order': return Colors.blue;
      case 'payment': return Colors.green;
      case 'delivery': return Colors.orange;
      case 'system': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order': return Icons.receipt;
      case 'payment': return Icons.payment;
      case 'delivery': return Icons.local_shipping;
      case 'system': return Icons.notifications;
      default: return Icons.notifications;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'order': return 'Orden';
      case 'payment': return 'Pago';
      case 'delivery': return 'Delivery';
      case 'system': return 'Sistema';
      default: return 'Otro';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _typeTabs.map((tab) => Tab(text: tab)).toList(),
          onTap: (index) {
            _loadData();
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatsCard(),
              _buildFilters(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _notificationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar notificaciones',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay notificaciones',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Todas las notificaciones aparecerán aquí',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final notifications = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) => _buildNotificationCard(notifications[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
} 