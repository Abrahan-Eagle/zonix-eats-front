import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zonix/features/services/dispute_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class BuyerDisputeDetailPage extends StatefulWidget {
  const BuyerDisputeDetailPage({
    super.key,
    required this.disputeId,
    this.service,
  });

  final int disputeId;
  final DisputeService? service;

  @override
  State<BuyerDisputeDetailPage> createState() => _BuyerDisputeDetailPageState();
}

class _BuyerDisputeDetailPageState extends State<BuyerDisputeDetailPage> {
  late final DisputeService _service;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dispute;
  StreamSubscription<Map<String, dynamic>>? _pusherSub;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DisputeService();
    _load();
    _subscribeToRealtimeDispute();
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
      final data = await _service.getDisputeById(widget.disputeId);
      if (!mounted) return;
      setState(() {
        _dispute = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _subscribeToRealtimeDispute() {
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
      final disputeId = int.tryParse(payload['dispute_id']?.toString() ?? '');
      if (disputeId != widget.disputeId) return;

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La disputa se actualizo en tiempo real.')),
      );
    });
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de disputa')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final dispute = _dispute ?? <String, dynamic>{};
    final status = (dispute['status'] ?? '').toString();
    final resolution = (dispute['resolution'] ?? '').toString();
    final type = (dispute['type'] ?? '').toString();
    final orderId = dispute['order_id']?.toString() ?? '—';
    final description = (dispute['description'] ?? '').toString();
    final adminNotes = (dispute['admin_notes'] ?? '').toString();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #$orderId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _chip(DisputeService.statusLabel(status)),
                  const SizedBox(height: 12),
                  _kv('Tipo', DisputeService.typeLabel(type)),
                  if (resolution.isNotEmpty) _kv('Resolución', resolution),
                  _kv('Creada', _formatDate(dispute['created_at'])),
                  _kv('Resuelta', _formatDate(dispute['resolved_at'])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description.isEmpty ? '—' : description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notas de soporte/admin',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(adminNotes.isEmpty ? 'Aún sin notas de resolución.' : adminNotes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              key,
              style: const TextStyle(color: AppColors.gray, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
