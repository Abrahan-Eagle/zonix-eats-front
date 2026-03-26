import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';

class AdminDisputesPage extends StatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  State<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends State<AdminDisputesPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _disputes = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _filterStatus;

  static const _statusFilters = <String, String>{
    '': 'Todos',
    'pending': 'Pendiente',
    'in_review': 'En revisión',
    'resolved': 'Resuelto',
    'closed': 'Cerrado',
  };

  static const _resolutionOptions = <String, String>{
    'refund': 'Reembolso',
    'replacement': 'Reemplazo',
    'credit': 'Crédito',
    'dismissed': 'Desestimado',
    'warning': 'Advertencia',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadStats();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await context.read<AdminService>().getDisputeStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _disputes = [];
    });
    try {
      final result = await context.read<AdminService>().getDisputes(
            page: 1,
            status: (_filterStatus != null && _filterStatus!.isNotEmpty)
                ? _filterStatus
                : null,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _disputes = list;
        _hasMore = _page < lastPage;
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

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _page++;
    try {
      final result = await context.read<AdminService>().getDisputes(
            page: _page,
            status: (_filterStatus != null && _filterStatus!.isNotEmpty)
                ? _filterStatus
                : null,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _disputes.addAll(list);
        _hasMore = _page < lastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      _page--;
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadData(), _loadStats()]);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.orange;
      case 'in_review':
        return AppColors.blue;
      case 'resolved':
        return AppColors.green;
      case 'closed':
        return AppColors.stitchSlate;
      default:
        return AppColors.stitchSlate;
    }
  }

  String _statusLabel(String status) {
    return _statusFilters[status] ?? status;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return safeString(raw);
    }
  }

  void _showDisputeSheet(Map<String, dynamic> dispute) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disputeId = safeInt(dispute['id']);
    final status = safeString(dispute['status']);
    final canResolve = status == 'pending' || status == 'in_review';

    String selectedResolution = _resolutionOptions.keys.first;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.cardBg(context),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: canResolve ? 0.75 : 0.55,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.white38 : AppColors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Disputa #$disputeId',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailRow(Icons.category, 'Tipo',
                        safeString(dispute['type'])),
                    _detailRow(Icons.receipt_long, 'Orden',
                        '#${safeInt(dispute['order_id'])}'),
                    _detailRow(Icons.calendar_today, 'Fecha',
                        _formatDate(dispute['created_at'])),
                    const SizedBox(height: 12),
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.grayLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        safeString(dispute['description'], 'Sin descripción'),
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (canResolve) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Resolver disputa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedResolution,
                        decoration: InputDecoration(
                          labelText: 'Resolución',
                          labelStyle: TextStyle(
                            color: AppColors.secondaryText(context),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.grayDark
                              : AppColors.grayLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _resolutionOptions.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedResolution = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Notas del admin',
                          labelStyle: TextStyle(
                            color: AppColors.secondaryText(context),
                          ),
                          hintText: 'Escribe una nota...',
                          hintStyle: TextStyle(
                            color: AppColors.secondaryText(context),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.grayDark
                              : AppColors.grayLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await context
                                .read<AdminService>()
                                .resolveDispute(
                                  disputeId,
                                  selectedResolution,
                                  notesController.text.isNotEmpty
                                      ? notesController.text
                                      : null,
                                );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _loadData();
                            _loadStats();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Disputa resuelta'),
                              ),
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Resolver'),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == '#0') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryText(context)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Disputas'),
        backgroundColor: isDark ? AppColors.grayDark : AppColors.blueDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_stats.isNotEmpty) _buildStatsBar(),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusFilters.entries.map((e) {
                final selected = (_filterStatus ?? '') == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _filterChip(e.value, selected, () {
                    setState(() => _filterStatus = e.key);
                    _loadData();
                  }),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = safeInt(_stats['pending'], safeInt(_stats['data']?['pending']));
    final resolved = safeInt(_stats['resolved'], safeInt(_stats['data']?['resolved']));
    final total = safeInt(_stats['total'], safeInt(_stats['data']?['total']));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.grayLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _statItem('Pendientes', '$pending', AppColors.orange),
          _statDivider(),
          _statItem('Resueltas', '$resolved', AppColors.green),
          _statDivider(),
          _statItem('Total', '$total', AppColors.blue),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.white12
          : AppColors.black12,
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.grayDark
                  : AppColors.grayLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : AppColors.secondaryText(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.error(context)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText(context))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel,
                size: 48, color: AppColors.secondaryText(context)),
            const SizedBox(height: 12),
            Text('No se encontraron disputas',
                style: TextStyle(color: AppColors.secondaryText(context))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _disputes.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _disputes.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildDisputeCard(_disputes[index]);
        },
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = safeString(dispute['status']);
    final type = safeString(dispute['type']);
    final description = safeString(dispute['description']);
    final date = _formatDate(dispute['created_at']);

    return GestureDetector(
      onTap: () => _showDisputeSheet(dispute),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.white12 : AppColors.black12,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        _statusColor(status).withValues(alpha: 0.15),
                    child: Icon(Icons.gavel,
                        size: 18, color: _statusColor(status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.isNotEmpty ? type : 'Disputa',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
