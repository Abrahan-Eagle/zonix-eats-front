import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Enlace de red del dispositivo (Wi‑Fi o datos). No hace ping al API: evita peticiones
/// extra, competencia con GET reales y esperas de ~3s cuando el HEAD fallaba pero el GET sí podía ir.
/// Atajo a caché solo si no hay interfaz de red (modo avión / sin datos).
class ConnectivityService extends ChangeNotifier {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance!;

  /// True si hay Wi‑Fi o datos móviles (no modo avión / sin interfaz).
  static bool get isConnected => _instance?._hasNetwork ?? true;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _hasNetwork = true;

  bool get hasNetwork => _hasNetwork;

  ConnectivityService() {
    _instance = this;
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateNetwork(results);
    } catch (_) {}
    _sub = _connectivity.onConnectivityChanged.listen(_updateNetwork);
  }

  void _updateNetwork(List<ConnectivityResult> results) {
    final before = _hasNetwork;
    _hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (before != _hasNetwork) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
