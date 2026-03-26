import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _filterStatus;

  static const _statusFilters = <String, String>{
    '': 'Todos',
    'pending_payment': 'Pend. pago',
    'paid': 'Pagado',
    'processing': 'Procesando',
    'shipped': 'Enviado',
    'delivered': 'Entregado',
    'cancelled': 'Cancelado',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _orders = [];
    });
    try {
      final result = await context.read<AdminService>().getOrders(
            page: 1,
            status: (_filterStatus != null && _filterStatus!.isNotEmpty)
                ? _filterStatus
                : null,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _orders = list;
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
      final result = await context.read<AdminService>().getOrders(
            page: _page,
            status: (_filterStatus != null && _filterStatus!.isNotEmpty)
                ? _filterStatus
                : null,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _orders.addAll(list);
        _hasMore = _page < lastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      _page--;
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return AppColors.orange;
      case 'paid':
        return AppColors.blue;
      case 'processing':
        return AppColors.blue;
      case 'shipped':
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

  String _commerceName(Map<String, dynamic> order) {
    final commerce = order['commerce'] as Map<String, dynamic>?;
    if (commerce != null) return safeString(commerce['business_name']);
    return '';
  }

  void _showOrderSheet(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderId = safeInt(order['id']);
    String currentStatus = safeString(order['status']);

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
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
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
                            'Orden #$orderId',
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
                            color: _statusColor(currentStatus)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(currentStatus),
                            style: TextStyle(
                              color: _statusColor(currentStatus),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailRow(Icons.storefront, 'Comercio',
                        _commerceName(order)),
                    _detailRow(Icons.attach_money, 'Total',
                        '\$${safeDouble(order['total']).toStringAsFixed(2)}'),
                    _detailRow(Icons.calendar_today, 'Fecha',
                        _formatDate(order['created_at'])),
                    _detailRow(Icons.local_shipping, 'Delivery fee',
                        '\$${safeDouble(order['delivery_fee']).toStringAsFixed(2)}'),
                    _detailRow(Icons.person, 'Comprador',
                        _buyerName(order)),
                    const SizedBox(height: 20),
                    Text(
                      'Cambiar estado',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? AppColors.grayDark
                            : AppColors.grayLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _statusFilters.entries
                          .where((e) => e.key.isNotEmpty)
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => currentStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await context
                              .read<AdminService>()
                              .updateOrderStatus(orderId, currentStatus);
                          if (!ctx.mounted) return;
                          final messenger = ScaffoldMessenger.of(ctx);
                          Navigator.pop(ctx);
                          _loadData();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Estado actualizado'),
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
                        backgroundColor: AppColors.blue,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Guardar cambio'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _buyerName(Map<String, dynamic> order) {
    final user = order['user'] as Map<String, dynamic>?;
    if (user != null) return safeString(user['name']);
    final profile = order['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      return '${safeString(profile['first_name'])} ${safeString(profile['last_name'])}'
          .trim();
    }
    return '';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
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
        title: const Text('Órdenes'),
        backgroundColor: isDark ? AppColors.grayDark : AppColors.blueDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusFilters.entries.map((e) {
                final selected =
                    (_filterStatus ?? '') == e.key;
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
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long,
                size: 48, color: AppColors.secondaryText(context)),
            const SizedBox(height: 12),
            Text('No se encontraron órdenes',
                style: TextStyle(color: AppColors.secondaryText(context))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _orders.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _buildOrderCard(_orders[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = safeInt(order['id']);
    final status = safeString(order['status']);
    final total = safeDouble(order['total']);
    final commerce = _commerceName(order);
    final date = _formatDate(order['created_at']);

    return GestureDetector(
      onTap: () => _showOrderSheet(order),
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
                    child: Text(
                      '#$id',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commerce.isNotEmpty ? commerce : 'Orden #$id',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 4),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
