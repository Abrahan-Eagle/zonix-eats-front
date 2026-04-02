import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zonix/features/screens/orders/buyer_dispute_detail_page.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/services/dispute_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class BuyerDisputesPage extends StatefulWidget {
  const BuyerDisputesPage({
    super.key,
    this.initialOrderId,
    this.service,
  });

  final int? initialOrderId;
  final DisputeService? service;

  @override
  State<BuyerDisputesPage> createState() => _BuyerDisputesPageState();
}

class _BuyerDisputesPageState extends State<BuyerDisputesPage> {
  late final DisputeService _service;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _selectedStatus = 'all';
  StreamSubscription<Map<String, dynamic>>? _pusherSub;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DisputeService();
    _load();
    _subscribeToRealtimeDisputes();
  }

  @override
  void dispose() {
    _pusherSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getBuyerDisputes();
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(data['items'] as List? ?? []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _subscribeToRealtimeDisputes() {
    _pusherSub?.cancel();
    _pusherSub = PusherService.instance.eventStream.listen((event) async {
      final eventName = (event['canonicalEventName'] ?? event['eventName'])?.toString() ?? '';
      if (!eventName.contains('NotificationCreated')) return;

      final eventData = event['data'] is Map<String, dynamic>
          ? event['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final type = (eventData['type'] ?? '').toString();
      if (type != 'dispute') return;

      final payload = eventData['data'] is Map<String, dynamic>
          ? eventData['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final newStatus = (payload['new_status'] ?? '').toString();

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus.isEmpty
                ? 'Tu disputa fue actualizada.'
                : 'Tu disputa fue actualizada: ${DisputeService.statusLabel(newStatus)}',
          ),
        ),
      );
    });
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedStatus == 'all') return _items;
    return _items.where((item) => (item['status'] ?? '').toString() == _selectedStatus).toList();
  }

  bool _isRecentlyResolved(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    if (status != 'resolved' && status != 'closed') return false;
    final resolvedAtRaw = item['resolved_at'];
    if (resolvedAtRaw == null) return false;
    final resolvedAt = DateTime.tryParse(resolvedAtRaw.toString());
    if (resolvedAt == null) return false;
    return DateTime.now().difference(resolvedAt).inHours <= 24;
  }

  Future<void> _createDispute() async {
    final orderController = TextEditingController(
      text: widget.initialOrderId?.toString() ?? '',
    );
    final descriptionController = TextEditingController();
    String selectedType = 'other';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Crear disputa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID de orden',
                    hintText: 'Ej: 123',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'payment_issue', child: Text('Problema de pago')),
                    DropdownMenuItem(value: 'delivery_problem', child: Text('Problema de entrega')),
                    DropdownMenuItem(value: 'quality_issue', child: Text('Problema de calidad')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (v) => setLocalState(() => selectedType = v ?? 'other'),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Describe el problema con el mayor detalle posible',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      final orderId = int.tryParse(orderController.text.trim());
                      final description = descriptionController.text.trim();
                      if (orderId == null || orderId <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un ID de orden válido')),
                        );
                        return;
                      }
                      if (description.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La descripción debe tener al menos 10 caracteres')),
                        );
                        return;
                      }

                      setState(() => _submitting = true);
                      try {
                        await _service.createDispute(
                          orderId: orderId,
                          type: selectedType,
                          description: description,
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop(true);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceFirst('Exception: ', '')),
                            backgroundColor: AppColors.red,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disputa creada correctamente')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis disputas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDispute,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nueva disputa'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                      const SizedBox(height: 8),
                      Center(child: Text(_error!)),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.support_agent, size: 48, color: AppColors.gray),
                          SizedBox(height: 8),
                          Center(child: Text('Aún no tienes disputas registradas')),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por estado',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Todos')),
                                DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                                DropdownMenuItem(value: 'in_review', child: Text('En revisión')),
                                DropdownMenuItem(value: 'resolved', child: Text('Resuelta')),
                                DropdownMenuItem(value: 'closed', child: Text('Cerrada')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedStatus = v);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _filteredItems.isEmpty
                                ? ListView(
                                    children: const [
                                      SizedBox(height: 120),
                                      Icon(Icons.filter_alt_off, size: 44, color: AppColors.gray),
                                      SizedBox(height: 8),
                                      Center(child: Text('No hay disputas con ese filtro')),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                                    itemCount: _filteredItems.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) {
                                      final item = _filteredItems[i];
                          final status = (item['status'] ?? '').toString();
                          final type = (item['type'] ?? '').toString();
                          final description = (item['description'] ?? '').toString();
                          final orderId = item['order_id']?.toString() ?? '—';
                                      final recentlyResolved = _isRecentlyResolved(item);

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const Icon(Icons.report_problem_outlined),
                              onTap: () {
                                final disputeId = item['id'];
                                if (disputeId is! int) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BuyerDisputeDetailPage(disputeId: disputeId),
                                  ),
                                );
                              },
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text('Orden #$orderId · ${DisputeService.typeLabel(type)}'),
                                  ),
                                  if (recentlyResolved)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Resuelta hoy',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.grayLight,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  DisputeService.statusLabel(status),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                                    },
                                  ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
