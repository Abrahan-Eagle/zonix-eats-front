import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:provider/provider.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';

/// Pantalla Ubicación: permite ampliar el radio de búsqueda (1-400 km) como Facebook.
/// Muestra mapa con círculo de radio, opción sugerido vs personalizado, slider, Aplicar.
class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final _kmController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _addressLabel;
  bool _loadingLocation = true;
  String? _error;

  static const _primary = Color(0xFF3399FF);

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    final provider = context.read<SearchRadiusProvider>();
    _kmController.text = provider.radiusKm.round().toString();
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _error = null;
    });
    try {
      final loc = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = (loc['latitude'] as num).toDouble();
        _longitude = (loc['longitude'] as num).toDouble();
        _addressLabel = loc['address'] as String?;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _apply() async {
    final provider = context.read<SearchRadiusProvider>();
    final km = double.tryParse(_kmController.text) ?? provider.radiusKm;
    final clamped = km.clamp(1.0, 400.0);
    await provider.setRadius(clamped);
    await provider.setUseSuggestedRadius(false);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SearchRadiusProvider>();
    final radiusKm = double.tryParse(_kmController.text) ?? provider.radiusKm;
    final clampedKm = radiusKm.clamp(1.0, 400.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ubicación',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(theme),
                      const SizedBox(height: 16),
                      _buildMap(clampedKm),
                      const SizedBox(height: 24),
                      _buildRadioSugerido(theme, provider),
                      const SizedBox(height: 16),
                      _buildRadioPersonalizado(theme, provider),
                      if (!provider.useSuggestedRadius) ...[
                        const SizedBox(height: 16),
                        _buildSlider(theme, provider),
                        const SizedBox(height: 8),
                        _buildKmInput(theme),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Los cambios en el radio personalizado solo se aplican a la pestaña Explorar.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildApplyButton(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentLocation,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _addressLabel ?? 'Obteniendo ubicación...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(double radiusKm) {
    final center = latLng.LatLng(_latitude ?? 10.48, _longitude ?? -66.90);
    final radiusMeters = radiusKm * 1000;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _zoomForRadius(radiusKm),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.zonix',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: radiusMeters,
                      useRadiusInMeter: true,
                      color: _primary.withValues(alpha: 0.15),
                      borderColor: _primary.withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: () {
                  _mapController.move(center, _zoomForRadius(radiusKm));
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _zoomForRadius(double km) {
    if (km <= 2) return 14;
    if (km <= 5) return 12;
    if (km <= 20) return 10;
    if (km <= 50) return 8;
    if (km <= 100) return 7;
    if (km <= 200) return 6;
    return 5;
  }

  Widget _buildRadioSugerido(ThemeData theme, SearchRadiusProvider provider) {
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => provider.setUseSuggestedRadius(true),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: provider.useSuggestedRadius,
                onChanged: (_) => provider.setUseSuggestedRadius(true),
                activeColor: _primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Radio sugerido',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mostrarme publicaciones de esta zona.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioPersonalizado(ThemeData theme, SearchRadiusProvider provider) {
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => provider.setUseSuggestedRadius(false),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<bool>(
                value: false,
                groupValue: provider.useSuggestedRadius,
                onChanged: (_) => provider.setUseSuggestedRadius(false),
                activeColor: _primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Radio personalizado',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mostrarme únicamente publicaciones dentro de una distancia específica.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(ThemeData theme, SearchRadiusProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            Text('400 km', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        Slider(
          value: provider.radiusKm,
          min: 1,
          max: 400,
          divisions: 399,
          activeColor: _primary,
          onChanged: (v) {
            provider.setRadius(v);
            _kmController.text = v.round().toString();
          },
        ),
      ],
    );
  }

  Widget _buildKmInput(ThemeData theme) {
    return TextField(
      controller: _kmController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Kilómetros',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (v) {
        final n = double.tryParse(v);
        if (n != null) {
          context.read<SearchRadiusProvider>().setRadius(n.clamp(1, 400));
        }
      },
    );
  }

  Widget _buildApplyButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _apply,
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Aplicar',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
