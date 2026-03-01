import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget de mapa usando OpenStreetMap tiles (como en CorralX).
/// [polylinePoints]: puntos para dibujar una ruta (ej. moto → cliente).
class OsmMapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker>? markers;
  final List<LatLng>? polylinePoints;
  final Color? polylineColor;
  final double? polylineStrokeWidth;
  final Function(LatLng)? onTap;
  final double? height;
  final double? width;

  const OsmMapWidget({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.markers,
    this.polylinePoints,
    this.polylineColor,
    this.polylineStrokeWidth = 4.0,
    this.onTap,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 300,
      width: width ?? double.infinity,
      child: FlutterMap(
        mapController: MapController(),
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 5.0,
          maxZoom: 18.0,
          onTap: onTap != null ? (tapPosition, point) => onTap!(point) : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.zonix.app',
            maxZoom: 19,
          ),
          if (polylinePoints != null && polylinePoints!.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePoints!,
                  color: polylineColor ?? const Color(0xFF3399FF),
                  strokeWidth: polylineStrokeWidth ?? 4.0,
                ),
              ],
            ),
          if (markers != null && markers!.isNotEmpty)
            MarkerLayer(
              markers: markers!,
            ),
        ],
      ),
    );
  }
}

/// Helper para crear markers fácilmente
class MapMarker {
  static Marker create({
    required LatLng point,
    Widget? child,
    IconData iconData = Icons.location_on,
    Color? color,
    double size = 40.0,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      child: child ??
          Icon(
            iconData,
            color: color ?? Colors.red,
            size: size,
          ),
    );
  }
}
