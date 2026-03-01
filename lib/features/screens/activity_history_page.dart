import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({Key? key}) : super(key: key);

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  List<Map<String, dynamic>> activities = [];
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  String? selectedActivityType;
  DateTime? startDate;
  DateTime? endDate;

  final List<String> activityTypes = [
    'all',
    'login',
    'order_placed',
    'order_cancelled',
    'profile_updated',
    'review_posted',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final results = await Future.wait([
        ActivityService.getUserActivityHistory(
          page: 1,
          activityType: selectedActivityType,
          startDate: startDate,
          endDate: endDate,
        ),
        ActivityService.getActivityStats(),
      ]);

      setState(() {
        activities = results[0] as List<Map<String, dynamic>>;
        stats = results[1] as Map<String, dynamic>;
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error al cargar datos: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final newActivities = await ActivityService.getUserActivityHistory(
        page: currentPage + 1,
        activityType: selectedActivityType,
        startDate: startDate,
        endDate: endDate,
      );

      if (newActivities.isNotEmpty) {
        setState(() {
          activities.addAll(newActivities);
          currentPage++;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar más datos: $e');
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getActivityIcon(String type) {
    switch (type) {
      case 'login':
        return '🔐';
      case 'order_placed':
        return '🛒';
      case 'order_cancelled':
        return '❌';
      case 'profile_updated':
        return '👤';
      case 'review_posted':
        return '⭐';
      default:
        return '📝';
    }
  }

  String _getActivityTitle(String type) {
    switch (type) {
      case 'login':
        return 'Inicio de sesión';
      case 'order_placed':
        return 'Pedido realizado';
      case 'order_cancelled':
        return 'Pedido cancelado';
      case 'profile_updated':
        return 'Perfil actualizado';
      case 'review_posted':
        return 'Reseña publicada';
      default:
        return 'Actividad';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
                AppColors.headerGradientEnd(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Historial de Actividad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: IconThemeData(color: AppColors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (!isLoading && stats.isNotEmpty)
            Card(
              color: AppColors.cardBg(context),
              shadowColor: AppColors.orange.withValues(alpha: 0.10),
              elevation: 8,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', stats['total_activities']?.toString() ?? '0', context),
                    _buildStatCard('Este mes', stats['this_month']?.toString() ?? '0', context),
                    _buildStatCard('Esta semana', stats['this_week']?.toString() ?? '0', context),
                  ],
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : activities.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay actividades para mostrar', // TODO: internacionalizar
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: activities.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == activities.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final activity = activities[index];
                            return Card(
                              color: AppColors.cardBg(context),
                              shadowColor: AppColors.purple.withValues(alpha: 0.10),
                              elevation: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: ListTile(
                                leading: Text(_getActivityIcon(activity['activity_type'] ?? ''), style: TextStyle(fontSize: 28)),
                                title: Text(_getActivityTitle(activity['activity_type'] ?? ''), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText(context))),
                                subtitle: Text(activity['description'] ?? '', style: TextStyle(color: AppColors.secondaryText(context))),
                                trailing: activity['created_at'] != null ? Text(DateTime.tryParse(activity['created_at']) != null ? '${DateTime.parse(activity['created_at']).day}/${DateTime.parse(activity['created_at']).month}/${DateTime.parse(activity['created_at']).year}' : '', style: TextStyle(color: AppColors.secondaryText(context))) : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.accentButton(context),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final type = activity['activity_type'] ?? '';
    final description = activity['description'] ?? '';
    final createdAt = DateTime.tryParse(activity['created_at'] ?? '');
    return Card(
      color: AppColors.cardBg(context),
      shadowColor: AppColors.purple.withValues(alpha: 0.10),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Text(_getActivityIcon(type), style: TextStyle(fontSize: 28)),
        title: Text(_getActivityTitle(type), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText(context))),
        subtitle: Text(description, style: TextStyle(color: AppColors.secondaryText(context))),
        trailing: createdAt != null ? Text('${createdAt.day}/${createdAt.month}/${createdAt.year}', style: TextStyle(color: AppColors.secondaryText(context))) : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} minutos';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActivityTitle(activity['activity_type'] ?? '')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción: ${activity['description'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatDate(DateTime.tryParse(activity['created_at'] ?? '') ?? DateTime.now())}'),
            if (activity['metadata'] != null) ...[
              const SizedBox(height: 8),
              const Text('Detalles adicionales:'),
              ...(activity['metadata'] as Map<String, dynamic>).entries.map(
                (entry) => Text('• ${entry.key}: ${entry.value}'),
              ),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Actividades'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedActivityType,
              decoration: const InputDecoration(
                labelText: 'Tipo de actividad',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos'),
                ),
                ...activityTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getActivityTitle(type)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedActivityType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          startDate = date;
                        });
                      }
                    },
                    child: Text(startDate != null
                        ? 'Desde: ${startDate!.day}/${startDate!.month}/${startDate!.year}'
                        : 'Fecha inicio'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          endDate = date;
                        });
                      }
                    },
                    child: Text(endDate != null
                        ? 'Hasta: ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                        : 'Fecha fin'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedActivityType = null;
                startDate = null;
                endDate = null;
              });
              Navigator.of(context).pop();
              _loadData();
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadData();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
} 