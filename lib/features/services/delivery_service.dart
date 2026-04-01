import 'package:flutter/foundation.dart';
import 'package:zonix/models/order.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';
import '../utils/auth_utils.dart';
import 'error_handler.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class DeliveryService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> _availableOrdersMaps = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get myOrders => _myOrders;
  List<Map<String, dynamic>> get availableOrdersMaps => _availableOrdersMaps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _myOrders = await getDeliveryOrders();
    } catch (e) {
      _error = _sessionInvalidated ? null : ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availableOrdersMaps = await _getAvailableOrdersRaw();
    } catch (e) {
      _error = _sessionInvalidated ? null : ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableOrdersRaw() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/delivery/available-orders'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    // Solo 401 = token inválido. 403 en este API suele ser "sin permiso" o estado de negocio, no borrar sesión.
    if (response.statusCode == 401) {
      await _invalidateLocalSessionMarkers();
      throw Exception('Sesión inválida');
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    }
    throw Exception('Error al obtener órdenes disponibles: ${response.statusCode}');
  }

  int? _agentId;
  int? get agentId => _agentId;

  /// Evita usar agentId cacheado de otro token (nuevo login / migrate:fresh).
  String? _lastAuthTokenSnapshot;
  bool _sessionInvalidated = false;
  int? _lastMeHttpStatus;

  bool get sessionInvalidated => _sessionInvalidated;

  /// Devuelve true una vez si había que forzar re-login; limpia el flag.
  bool consumeSessionInvalidated() {
    final v = _sessionInvalidated;
    _sessionInvalidated = false;
    return v;
  }

  int? _parsePositiveInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  Future<void> _invalidateLocalSessionMarkers() async {
    try {
      await AuthUtils.clearTokens();
    } catch (e) {
      debugPrint('[DeliveryService] clearTokens error: $e');
    }
    _agentId = null;
    _lastAuthTokenSnapshot = null;
    _sessionInvalidated = true;
    notifyListeners();
  }

  String get agentProfileFailureMessage {
    switch (_lastMeHttpStatus) {
      case 404:
        return 'No hay repartidor vinculado a tu cuenta. Si eres empresa, registra al menos un repartidor.';
      case 401:
        return 'Sesión inválida. Vuelve a iniciar sesión.';
      case 403:
        return 'No tienes permiso para esta operación de repartidor.';
      default:
        return 'No se pudo obtener tu perfil de repartidor';
    }
  }

  Future<int?> getMyAgentId() async {
    final token = await AuthUtils.getToken();
    if (token == null) {
      _agentId = null;
      _lastAuthTokenSnapshot = null;
      return null;
    }
    if (_lastAuthTokenSnapshot != token) {
      _agentId = null;
      _lastAuthTokenSnapshot = token;
    }
    if (_agentId != null) return _agentId;

    Map<String, String> headers;
    try {
      headers = await AuthHelper.getAuthHeaders();
    } catch (_) {
      await _invalidateLocalSessionMarkers();
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/me'),
        headers: headers,
      );
      _lastMeHttpStatus = response.statusCode;

      if (response.statusCode == 401) {
        await _invalidateLocalSessionMarkers();
        return null;
      }
      if (response.statusCode == 403) {
        _agentId = null;
        notifyListeners();
        return null;
      }
      if (response.statusCode == 404) {
        _agentId = null;
        notifyListeners();
        return null;
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data != null &&
            data['success'] == true &&
            data['data'] != null &&
            data['data'] is Map) {
          final id = _parsePositiveInt((data['data'] as Map)['id']);
          if (id != null) {
            _agentId = id;
            _lastMeHttpStatus = null;
            notifyListeners();
            return _agentId;
          }
        }
      }
    } catch (_) {
      _lastMeHttpStatus = null;
    }
    return null;
  }

  // --- History state ---
  List<Order> _historyOrders = [];
  bool _historyLoading = false;
  String? _historyError;

  List<Order> get historyOrders => _historyOrders;
  bool get historyLoading => _historyLoading;
  String? get historyError => _historyError;

  Future<void> loadHistory({DateTime? startDate, DateTime? endDate}) async {
    final id = await getMyAgentId();
    if (id == null) {
      _historyLoading = false;
      _historyError = _sessionInvalidated ? null : agentProfileFailureMessage;
      notifyListeners();
      return;
    }
    _historyLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      _historyOrders = await getDeliveryHistory(id, startDate: startDate, endDate: endDate);
    } catch (e) {
      _historyError = _sessionInvalidated ? null : ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  // --- Earnings state ---
  Map<String, dynamic> _earningsMap = {};
  bool _earningsLoading = false;
  String? _earningsError;

  Map<String, dynamic> get earningsMap => _earningsMap;
  bool get earningsLoading => _earningsLoading;
  String? get earningsError => _earningsError;

  Future<void> loadEarnings({DateTime? startDate, DateTime? endDate}) async {
    final id = await getMyAgentId();
    if (id == null) {
      _earningsLoading = false;
      _earningsError = _sessionInvalidated ? null : agentProfileFailureMessage;
      notifyListeners();
      return;
    }
    _earningsLoading = true;
    _earningsError = null;
    notifyListeners();
    try {
      _earningsMap = await getDeliveryEarnings(id, startDate: startDate, endDate: endDate);
    } catch (e) {
      _earningsError = _sessionInvalidated ? null : ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _earningsLoading = false;
      notifyListeners();
    }
  }

  // --- Routes state ---
  List<Map<String, dynamic>> _routesList = [];
  bool _routesLoading = false;
  String? _routesError;

  List<Map<String, dynamic>> get routesList => _routesList;
  bool get routesLoading => _routesLoading;
  String? get routesError => _routesError;

  Future<void> loadRoutes() async {
    final id = await getMyAgentId();
    if (id == null) {
      _routesLoading = false;
      _routesError = _sessionInvalidated ? null : agentProfileFailureMessage;
      notifyListeners();
      return;
    }
    _routesLoading = true;
    _routesError = null;
    notifyListeners();
    try {
      _routesList = await getDeliveryRoutes(id);
    } catch (e) {
      _routesError = _sessionInvalidated ? null : ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _routesLoading = false;
      notifyListeners();
    }
  }

  static const String _ordersCacheKey = 'delivery_orders';

  /// Populates [_myOrders] from cache without showing loading spinner.
  Future<void> loadCachedOrders() async {
    final cached = await _getCachedJson(_ordersCacheKey);
    if (cached != null) {
      _myOrders = List<Map<String, dynamic>>.from(cached);
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getDeliveryOrders() async {
    if (!ConnectivityService.isConnected) {
      final cached = await _getCachedJson(_ordersCacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
    }
    try {
      final response = await _httpWithRetry(() => http.get(
        Uri.parse('$baseUrl/api/delivery/orders'),
        headers: _lastHeaders!,
      ));

      if (response.statusCode == 401) {
        await _invalidateLocalSessionMarkers();
        throw Exception('Sesión inválida');
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> result;
        if (data is Map && data['success'] == true && data['data'] != null) {
          result = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          result = List<Map<String, dynamic>>.from(data);
        } else {
          result = List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        _cacheJson(_ordersCacheKey, result);
        return result;
      } else {
        throw Exception('Error al obtener órdenes: ${response.statusCode}');
      }
    } catch (e) {
      if (!_isAuthError(e)) {
        final cached = await _getCachedJson(_ordersCacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
      }
      rethrow;
    }
  }

  Map<String, String>? _lastHeaders;

  Future<http.Response> _httpWithRetry(Future<http.Response> Function() fn) async {
    _lastHeaders = await AuthHelper.getAuthHeaders();
    try {
      return await fn();
    } catch (e) {
      if (_isNetworkError(e)) {
        await Future.delayed(const Duration(seconds: 2));
        return await fn();
      }
      rethrow;
    }
  }

  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') || s.contains('timeout') || s.contains('clientexception') || s.contains('connection');
  }

  bool _isAuthError(Object e) => e.toString().contains('Sesión inválida');

  void _cacheJson(String key, dynamic data) {
    CacheService.setRawJson(key, jsonEncode(data), expiration: const Duration(minutes: 10));
  }

  Future<dynamic> _getCachedJson(String key) async {
    final raw = await CacheService.getRawJson(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// Obtiene una orden por ID (para detalle desde notificación FCM).
  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (response.statusCode == 401) {
        await _invalidateLocalSessionMarkers();
        return null;
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update order status (for DeliveryOrdersPage)
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/status'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifyListeners();
          return;
        }
        throw Exception('Error updating order status: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error updating order status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get available orders for delivery
  Future<List<Order>> getAvailableOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/available-orders'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final payload = data['data'];
          if (payload is List) {
            return payload.map((json) => Order.fromJson(json)).toList();
          }
          if (payload is Map<String, dynamic>) {
            final rawItems = payload['items'] ?? payload['data'] ?? [];
            if (rawItems is List) {
              return rawItems.map((json) => Order.fromJson(json)).toList();
            }
          }
        }
        return [];
      } else {
        throw Exception('Error fetching available orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get orders assigned to delivery agent
  Future<List<Order>> getAssignedOrders(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/assigned-orders/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final payload = data['data'];
          if (payload is List) {
            return payload.map((json) => Order.fromJson(json)).toList();
          }
          if (payload is Map<String, dynamic>) {
            final rawItems = payload['items'] ?? payload['data'] ?? [];
            if (rawItems is List) {
              return rawItems.map((json) => Order.fromJson(json)).toList();
            }
          }
        }
        return [];
      } else {
        throw Exception('Error fetching assigned orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> acceptOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/accept'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'notes': ''}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Order.fromJson(data['data']);
        }
        throw Exception('Error accepting order: Invalid response');
      } else {
        throw Exception('Error accepting order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  Future<bool> notifyArrived(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/arrived'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> scanPickup(int orderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/scan-pickup'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error');
    } catch (e) {
      throw Exception('Error al verificar recogida: $e');
    }
  }

  Future<Map<String, dynamic>?> scanDelivery(int orderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/scan-delivery'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error');
    } catch (e) {
      throw Exception('Error al verificar entrega: $e');
    }
  }

  Future<bool> rejectOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/reject'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/delivery/status - estado working del agente actual
  Future<bool> getWorkingStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/status'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data']['working'] as bool?) ?? false;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// PATCH /api/delivery/working - actualizar disponibilidad (working)
  Future<bool> updateWorking(bool working) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/delivery/working'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'working': working}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Get delivery history
  Future<List<Order>> getDeliveryHistory(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/delivery/history/$deliveryAgentId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 401) {
        await _invalidateLocalSessionMarkers();
        throw Exception('Sesión inválida');
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final payload = data['data'];
          if (payload is List) {
            return payload.map((json) => Order.fromJson(json)).toList();
          }
          if (payload is Map<String, dynamic>) {
            final rawItems = payload['items'] ?? payload['data'] ?? [];
            if (rawItems is List) {
              return rawItems.map((json) => Order.fromJson(json)).toList();
            }
          }
        }
        return [];
      } else {
        throw Exception('Error fetching delivery history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get delivery earnings
  Future<Map<String, dynamic>> getDeliveryEarnings(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/delivery/earnings/$deliveryAgentId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 401) {
        await _invalidateLocalSessionMarkers();
        throw Exception('Sesión inválida');
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error fetching delivery earnings: Invalid response');
      } else {
        throw Exception('Error fetching delivery earnings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get delivery routes
  Future<List<Map<String, dynamic>>> getDeliveryRoutes(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/routes/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 401) {
        await _invalidateLocalSessionMarkers();
        throw Exception('Sesión inválida');
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error fetching delivery routes: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDeliveryLocation(double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/location/update'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Error updating delivery location: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error updating delivery location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating delivery location: $e');
    }
  }

  // Get delivery statistics
  Future<Map<String, dynamic>> getDeliveryStatistics(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/statistics/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error fetching delivery statistics: Invalid response');
      } else {
        throw Exception('Error fetching delivery statistics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Report delivery issue
  Future<void> reportDeliveryIssue(int orderId, String issue, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/report-issue'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'issue': issue,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Error reporting delivery issue: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error reporting delivery issue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reporting delivery issue: $e');
    }
  }
} 