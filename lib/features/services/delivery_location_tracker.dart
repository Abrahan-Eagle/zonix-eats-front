import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'delivery_service.dart';

/// Sends the delivery agent's GPS position to the backend every [intervalSeconds]
/// while active. Exposes [positionStream] so UI can update a marker in real time.
class DeliveryLocationTracker extends ChangeNotifier {
  final DeliveryService _deliveryService;
  final int intervalSeconds;

  Timer? _timer;
  LatLng? _lastPosition;
  bool _active = false;

  LatLng? get lastPosition => _lastPosition;
  bool get isTracking => _active;

  final StreamController<LatLng> _positionController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get positionStream => _positionController.stream;

  DeliveryLocationTracker(this._deliveryService, {this.intervalSeconds = 20});

  void start() {
    if (_active) return;
    _active = true;
    _tick();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => _tick());
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _active = false;
    notifyListeners();
  }

  Future<void> _tick() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      _lastPosition = LatLng(pos.latitude, pos.longitude);
      _positionController.add(_lastPosition!);
      notifyListeners();

      try {
        await _deliveryService.updateDeliveryLocation(pos.latitude, pos.longitude);
      } catch (e) {
        debugPrint('GPS tracker: backend update failed: $e');
      }
    } catch (e) {
      debugPrint('GPS tracker: position error: $e');
    }
  }

  /// Force an immediate position fetch + emit (for initial map load).
  Future<LatLng?> fetchNow() async {
    await _tick();
    return _lastPosition;
  }

  @override
  void dispose() {
    stop();
    _positionController.close();
    super.dispose();
  }
}
