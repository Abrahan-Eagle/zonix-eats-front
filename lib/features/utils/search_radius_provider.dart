import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para el radio de búsqueda (1-400 km) estilo Facebook.
/// Persiste en SharedPreferences. Usado en Explorar para filtrar restaurantes/productos.
class SearchRadiusProvider extends ChangeNotifier {
  static const String _keyRadiusKm = 'search_radius_km';
  static const String _keyUseSuggested = 'search_radius_use_suggested';
  static const String _keyDeliveryAddress = 'delivery_address_label';
  static const double _defaultRadius = 5.0;
  static const double _minRadius = 1.0;
  static const double _maxRadius = 400.0;

  double _radiusKm = _defaultRadius;
  bool _useSuggestedRadius = false;
  String? _deliveryAddressLabel;

  double get radiusKm => _radiusKm;
  bool get useSuggestedRadius => _useSuggestedRadius;
  /// Dirección de entrega (geocodificación inversa desde GPS). Para header "Entregando a".
  String? get deliveryAddressLabel => _deliveryAddressLabel;
  double get minRadius => _minRadius;
  double get maxRadius => _maxRadius;

  SearchRadiusProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _radiusKm = prefs.getDouble(_keyRadiusKm) ?? _defaultRadius;
    _radiusKm = _radiusKm.clamp(_minRadius, _maxRadius);
    _useSuggestedRadius = prefs.getBool(_keyUseSuggested) ?? false;
    _deliveryAddressLabel = prefs.getString(_keyDeliveryAddress);
    notifyListeners();
  }

  Future<void> setDeliveryAddressLabel(String? label) async {
    _deliveryAddressLabel = label;
    final prefs = await SharedPreferences.getInstance();
    if (label != null) {
      await prefs.setString(_keyDeliveryAddress, label);
    } else {
      await prefs.remove(_keyDeliveryAddress);
    }
    notifyListeners();
  }

  Future<void> setRadius(double km) async {
    _radiusKm = km.clamp(_minRadius, _maxRadius);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRadiusKm, _radiusKm);
    notifyListeners();
  }

  Future<void> setUseSuggestedRadius(bool value) async {
    _useSuggestedRadius = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseSuggested, value);
    notifyListeners();
  }

  /// Radio efectivo: si useSuggestedRadius=true, usar ~5 km; si no, usar radiusKm
  double get effectiveRadiusKm => _useSuggestedRadius ? 5.0 : _radiusKm;
}
