import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';

/// Network link (Wi-Fi / mobile) + periodic API reachability check.
///
/// Three states: online (interface + API OK), degraded (interface OK but API
/// unreachable), offline (no interface). Consumers use [hasNetwork] for the
/// interface layer and [apiReachable] for the deeper check.
class ConnectivityService extends ChangeNotifier {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance!;

  static bool get isConnected => _instance?._hasNetwork ?? true;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _healthTimer;
  bool _hasNetwork = true;
  bool _apiReachable = true;

  bool get hasNetwork => _hasNetwork;
  bool get apiReachable => _apiReachable;

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
    // Defer first health-check 15s so it doesn't compete with initial data
    // fetches (products, profile, etc.) on slow networks.
    Future.delayed(const Duration(seconds: 15), () {
      _checkApiHealth();
      _healthTimer = Timer.periodic(
          const Duration(seconds: 90), (_) => _checkApiHealth());
    });
  }

  void _updateNetwork(List<ConnectivityResult> results) {
    final before = _hasNetwork;
    _hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (before != _hasNetwork) {
      if (_hasNetwork) _checkApiHealth();
      notifyListeners();
    }
  }

  Future<void> _checkApiHealth() async {
    if (!_hasNetwork) {
      if (_apiReachable) {
        _apiReachable = false;
        notifyListeners();
      }
      return;
    }
    try {
      final uri = Uri.parse('${AppConfig.apiUrl}/api/ping');
      final response = await http.head(uri).timeout(const Duration(seconds: 5));
      final reachable = response.statusCode < 500;
      if (reachable != _apiReachable) {
        _apiReachable = reachable;
        notifyListeners();
      }
    } catch (_) {
      if (_apiReachable) {
        _apiReachable = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _healthTimer?.cancel();
    super.dispose();
  }
}
