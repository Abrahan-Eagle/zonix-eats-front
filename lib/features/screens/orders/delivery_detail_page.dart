import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Pantalla de detalle del repartidor asignado a una orden (desde pedido actual).
class DeliveryDetailPage extends StatefulWidget {
  const DeliveryDetailPage({
    super.key,
    required this.orderId,
    this.deliveryName,
    this.deliveryRating,
  });

  final int orderId;
  final String? deliveryName;
  final String? deliveryRating;

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  Map<String, dynamic>? _agent;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await OrderService().getDeliveryAgentForOrder(widget.orderId);
      if (mounted) setState(() { _agent = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardBg(context) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    const primary = Color(0xFF3399FF);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tu repartidor',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', textAlign: TextAlign.center, style: TextStyle(color: textSecondary)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: primary.withValues(alpha: 0.2),
                              child: Icon(Icons.delivery_dining, size: 48, color: primary),
                            ),
                            const SizedBox(height: 16),
                            if (_agent != null) ...[
                              Text(
                                _agent!['name']?.toString() ?? widget.deliveryName ?? 'Repartidor asignado',
                                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                              if (_agent!['vehicle'] != null)
                                Text(
                                  _agent!['vehicle'].toString(),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary),
                                ),
                            ] else
                              Text(
                                widget.deliveryName ?? 'Repartidor asignado',
                                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_agent?['phone'] != null)
                              ListTile(
                                leading: Icon(Icons.phone_outlined, color: primary),
                                title: const Text('Teléfono'),
                                subtitle: Text(_agent!['phone'].toString()),
                              ),
                            if (_agent?['current_location'] is Map)
                              ListTile(
                                leading: Icon(Icons.location_on_outlined, color: primary),
                                title: const Text('Ubicación actual'),
                                subtitle: const Text('En camino a tu dirección'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
