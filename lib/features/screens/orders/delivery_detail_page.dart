import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla "Detalle del Repartidor" según template. Soporta dark y light mode.
class DeliveryDetailPage extends StatefulWidget {
  const DeliveryDetailPage({
    super.key,
    required this.orderId,
    this.deliveryName,
    this.deliveryRating,
    this.commerceName,
  });

  final int orderId;
  final String? deliveryName;
  final String? deliveryRating;
  /// Nombre del comercio para abrir el chat de la orden (Mensaje).
  final String? commerceName;

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
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A2E46);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF94A3B8);
    const primary = Color(0xFF3299FF);
    final scaffoldBg = isDark ? AppColors.backgroundDark : const Color(0xFFF5F7F8);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final statusBg = isDark ? primary.withValues(alpha: 0.2) : primary.withValues(alpha: 0.1);
    final verifiedBg = isDark ? primary.withValues(alpha: 0.25) : const Color(0xFFEFF6FF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Detalle del Repartidor',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.cardBg(context) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary)),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_agent == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 22, color: primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Aún no hay repartidor asignado para este pedido.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      _buildProfileCard(surfaceColor, borderColor, primary, textPrimary, textSecondary, textMuted, verifiedBg, isDark),
                      const SizedBox(height: 16),
                      _buildStatusBanner(statusBg, primary, textPrimary, isDark),
                      const SizedBox(height: 16),
                      _buildStatisticsRow(surfaceColor, borderColor, textPrimary, textMuted, isDark),
                      const SizedBox(height: 16),
                      _buildVehicleCard(surfaceColor, borderColor, primary, textPrimary, textMuted, isDark),
                      const SizedBox(height: 16),
                      _buildBioCard(surfaceColor, borderColor, textPrimary, textMuted, isDark),
                      const SizedBox(height: 24),
                      _buildContactSection(primary, textPrimary, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard(
    Color surfaceColor,
    Color borderColor,
    Color primary,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color verifiedBg,
    bool isDark,
  ) {
    final name = _agent?['name']?.toString() ?? widget.deliveryName ?? 'Repartidor asignado';
    final rating = _agent?['rating'] ?? widget.deliveryRating;
    final reviewsCount = _agent?['reviews_count'];
    final photoUrl = _agent?['photo_url'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _buildProfileAvatar(name, photoUrl, primary, surfaceColor, isDark),
              if (_agent?['verified'] == true)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceColor, width: 3),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 22),
              const SizedBox(width: 4),
              Text(
                rating != null ? rating.toString() : '—',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              Builder(
                builder: (context) {
                  final n = reviewsCount is num ? reviewsCount.round() : (int.tryParse(reviewsCount?.toString() ?? '0') ?? 0);
                  return Text(
                    n > 0 ? ' (${_formatNumber(n)} reseñas)' : ' (Sin reseñas aún)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_agent?['verified'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: verifiedBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'VERIFICADO',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Color statusBg, Color primary, Color textPrimary, bool isDark) {
    final loc = _agent?['current_location'];
    final customerLoc = _agent?['customer_location'];
    final hasLocation = loc is Map && loc['lat'] != null && loc['lng'] != null;
    final hasCustomerLoc = customerLoc is Map && customerLoc['lat'] != null && customerLoc['lng'] != null;
    final canOpenMapsRoute = hasLocation && hasCustomerLoc;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasLocation) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              hasLocation ? 'En camino a tu ubicación' : 'Asignado a tu pedido',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
              textAlign: TextAlign.center,
            ),
          ),
          if (canOpenMapsRoute)
            IconButton(
              onPressed: () {
                final fromLat = (loc['lat'] as num).toDouble();
                final fromLng = (loc['lng'] as num).toDouble();
                final toLat = (customerLoc['lat'] as num).toDouble();
                final toLng = (customerLoc['lng'] as num).toDouble();
                _openGoogleMapsRoute(fromLat, fromLng, toLat, toLng);
              },
              icon: Icon(Icons.directions, size: 24, color: primary),
              tooltip: 'Ver ruta en Google Maps',
            )
          else if (hasLocation)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailPage(orderId: widget.orderId),
                  ),
                );
              },
              icon: Icon(Icons.map_outlined, size: 22, color: primary),
              tooltip: 'Ver en mapa',
            ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMapsRoute(double fromLat, double fromLng, double toLat, double toLng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/$fromLat,$fromLng/$toLat,$toLng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStatisticsRow(Color surfaceColor, Color borderColor, Color textPrimary, Color textMuted, bool isDark) {
    final deliveries = _agent?['deliveries_count'];
    final years = _agent?['years_active'];
    final puntual = _agent?['punctuality_percent'];

    return Row(
      children: [
        _statCard(surfaceColor, borderColor, 'Entregas', deliveries != null ? _formatNumber(deliveries) : '—', textPrimary, textMuted, isDark),
        const SizedBox(width: 12),
        _statCard(surfaceColor, borderColor, 'Años', years != null ? years.toString() : '—', textPrimary, textMuted, isDark),
        const SizedBox(width: 12),
        _statCard(surfaceColor, borderColor, 'Puntual', puntual != null ? '$puntual%' : '—', textPrimary, textMuted, isDark),
      ],
    );
  }

  Widget _statCard(Color surfaceColor, Color borderColor, String label, String value, Color textPrimary, Color textMuted, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Color surfaceColor, Color borderColor, Color primary, Color textPrimary, Color textMuted, bool isDark) {
    final vehicle = _agent?['vehicle']?.toString() ?? 'Moto';
    final plate = _agent?['license_plate'] ?? _agent?['plate'];
    final color = _agent?['vehicle_color'];
    final model = _agent?['vehicle_model'];
    final vehicleIcon = _vehicleIcon(vehicle, textPrimary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(vehicleIcon, size: 28, color: textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VEHÍCULO',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                    children: [
                      TextSpan(text: vehicle),
                      if (plate != null && plate.toString().isNotEmpty)
                        TextSpan(text: ' - ', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                      if (plate != null && plate.toString().isNotEmpty)
                        TextSpan(text: plate.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: primary)),
                    ],
                  ),
                ),
                if (color != null || model != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (color != null)
                        Text(
                          'Color: $color',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted),
                        ),
                      if (model != null)
                        Text(
                          'Modelo: $model',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(Color surfaceColor, Color borderColor, Color textPrimary, Color textMuted, bool isDark) {
    final name = _agent?['name']?.toString() ?? widget.deliveryName ?? 'Repartidor';
    final firstName = name.split(' ').first;
    final reviews = _agent?['reviews'];
    String displayText = 'Tu repartidor te llevará el pedido. Cuando llegue, podrás calificarlo y dejar tu reseña.';
    if (reviews is List && reviews.isNotEmpty) {
      final comments = reviews
          .where((r) => r is Map && r['comment'] != null && r['comment'].toString().trim().isNotEmpty)
          .map((r) => (r as Map)['comment'].toString().trim())
          .toList();
      if (comments.isNotEmpty) {
        displayText = comments.first;
        if (comments.length > 1) {
          displayText = comments.take(2).join('\n\n');
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOBRE $firstName'.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(Color primary, Color textPrimary, bool isDark) {
    final commerceName = widget.commerceName ?? 'Comercio';

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BuyerOrderChatPage(orderId: widget.orderId, commerceName: commerceName),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.chat_bubble_outline, size: 22),
        label: const Text('Mensaje'),
      ),
    );
  }

  String _formatNumber(dynamic n) {
    if (n == null) return '0';
    final v = n is num ? n.toInt() : int.tryParse(n.toString()) ?? 0;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toString();
  }

  /// Avatar: foto del repartidor si [photoUrl] es válida; si falla o no hay URL, muestra inicial.
  Widget _buildProfileAvatar(String name, String? photoUrl, Color primary, Color surfaceColor, bool isDark) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    final placeholder = CircleAvatar(
      radius: 48,
      backgroundColor: isDark ? primary.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.bold, color: primary),
      ),
    );
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return placeholder;
    }
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          ClipOval(
            child: Image.network(
              photoUrl.trim(),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: surfaceColor,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _vehicleIcon(String vehicleType, Color color) {
    final v = vehicleType.toLowerCase();
    if (v.contains('bicycle') || v.contains('bici')) return Icons.directions_bike;
    if (v.contains('car') || v.contains('auto')) return Icons.directions_car;
    if (v.contains('truck')) return Icons.local_shipping;
    return Icons.two_wheeler;
  }
}
