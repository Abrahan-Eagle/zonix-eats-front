import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

final logger = Logger();

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _activityData;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadActivityHistory();
  }

  Future<void> _loadActivityHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _profileService.getActivityHistory();
      setState(() {
        _activityData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      logger.e('Error loading activity history: $e');
    }
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'unknown';
    final description = activity['description'] ?? '';
    final createdAt = activity['created_at'] ?? '';
    final icon = _getActivityIcon(type);
    final color = _getActivityColor(type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          _getActivityTitle(type),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // Mostrar detalles de la actividad
          _showActivityDetails(activity);
        },
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'review':
        return Icons.star;
      case 'payment':
        return Icons.payment;
      case 'login':
        return Icons.login;
      case 'profile':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'review':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'login':
        return Colors.purple;
      case 'profile':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getActivityTitle(String type) {
    switch (type) {
      case 'order':
        return 'Orden';
      case 'review':
        return 'Reseña';
      case 'payment':
        return 'Pago';
      case 'login':
        return 'Inicio de sesión';
      case 'profile':
        return 'Perfil';
      default:
        return 'Actividad';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActivityTitle(activity['type'] ?? 'unknown')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción: ${activity['description'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatDate(activity['created_at'] ?? '')}'),
            if (activity['details'] != null) ...[
              const SizedBox(height: 8),
              Text('Detalles: ${activity['details']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Actividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivityHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filtrar: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todas')),
                    DropdownMenuItem(value: 'order', child: Text('Órdenes')),
                    DropdownMenuItem(value: 'review', child: Text('Reseñas')),
                    DropdownMenuItem(value: 'payment', child: Text('Pagos')),
                    DropdownMenuItem(value: 'login', child: Text('Sesiones')),
                    DropdownMenuItem(value: 'profile', child: Text('Perfil')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          // Lista de actividades
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar el historial',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red[300],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadActivityHistory,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _activityData == null || _activityData!['data'] == null
                        ? const Center(
                            child: Text('No hay actividad para mostrar'),
                          )
                        : ListView.builder(
                            itemCount: _activityData!['data'].length,
                            itemBuilder: (context, index) {
                              final activity = _activityData!['data'][index];
                              if (_selectedFilter != 'all' &&
                                  activity['type'] != _selectedFilter) {
                                return const SizedBox.shrink();
                              }
                              return _buildActivityItem(activity);
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 