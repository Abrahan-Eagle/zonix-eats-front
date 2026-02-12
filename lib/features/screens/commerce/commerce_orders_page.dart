import 'package:flutter/material.dart';
import 'package:zonix/models/commerce_order.dart';
import 'package:zonix/features/services/commerce_order_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceOrdersPage extends StatefulWidget {
  const CommerceOrdersPage({Key? key}) : super(key: key);

  @override
  State<CommerceOrdersPage> createState() => _CommerceOrdersPageState();
}

class _CommerceOrdersPageState extends State<CommerceOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommerceOrder> _orders = [];
  bool _loading = true;
  String? _error;
  String _currentFilter = '';

  final List<Map<String, String>> _tabs = [
    {'key': '', 'label': 'Todas'},
    {'key': 'pending_payment', 'label': 'Pendientes'},
    {'key': 'processing', 'label': 'En Proceso'},
    {'key': 'shipped', 'label': 'Enviadas'},
    {'key': 'delivered', 'label': 'Entregadas'},
    {'key': 'cancelled', 'label': 'Canceladas'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _currentFilter = _tabs[_tabController.index]['key']!);
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _currentFilter.isEmpty ? null : _currentFilter;
      final orders = await CommerceOrderService.getOrders(status: status);
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'processing':
        return AppColors.orange;
      case 'shipped':
        return AppColors.blue;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.gray),
                  const SizedBox(height: 16),
                  Text(
                    'No hay órdenes',
                    style: TextStyle(fontSize: 18, color: AppColors.gray),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                order.customerName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '\$${order.total.toStringAsFixed(2)} · ${order.statusText} · ${_formatDate(order.createdAt)}',
              ),
              trailing: Chip(
                label: Text(order.statusText, style: const TextStyle(fontSize: 11)),
                backgroundColor: _statusColor(order.status),
                labelStyle: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pushNamed(
                context,
                '/commerce/order/${order.id}',
                arguments: order,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
