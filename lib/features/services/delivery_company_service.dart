import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';
import 'error_handler.dart';

class DeliveryCompanyService extends ChangeNotifier {
  static String get _baseUrl => AppConfig.apiUrl;

  // --- Dashboard ---
  Map<String, dynamic> _dashboardData = {};
  bool _dashboardLoading = false;
  String? _dashboardError;

  Map<String, dynamic> get dashboardData => _dashboardData;
  bool get dashboardLoading => _dashboardLoading;
  String? get dashboardError => _dashboardError;

  Future<void> loadDashboard() async {
    _dashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/delivery-company/dashboard'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _dashboardData = Map<String, dynamic>.from(body['data']);
        }
      } else {
        _dashboardError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
      }
    } catch (e) {
      _dashboardError = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  // --- Agents ---
  List<Map<String, dynamic>> _agents = [];
  bool _agentsLoading = false;
  String? _agentsError;

  List<Map<String, dynamic>> get agents => _agents;
  bool get agentsLoading => _agentsLoading;
  String? get agentsError => _agentsError;

  Future<void> loadAgents() async {
    _agentsLoading = true;
    _agentsError = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/delivery-company/agents'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _agents = List<Map<String, dynamic>>.from(body['data']);
        }
      } else {
        _agentsError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
      }
    } catch (e) {
      _agentsError = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _agentsLoading = false;
      notifyListeners();
    }
  }

  // --- Agents for map (with location + current order) ---
  List<Map<String, dynamic>> _mapAgents = [];
  bool _mapAgentsLoading = false;
  String? _mapAgentsError;

  List<Map<String, dynamic>> get mapAgents => _mapAgents;
  bool get mapAgentsLoading => _mapAgentsLoading;
  String? get mapAgentsError => _mapAgentsError;

  Future<void> loadAgentsForMap({String? status}) async {
    _mapAgentsLoading = true;
    _mapAgentsError = null;
    notifyListeners();
    try {
      final params = <String, String>{'active_only': 'true'};
      if (status != null && status.isNotEmpty) params['status'] = status;
      final uri = Uri.parse('$_baseUrl/api/delivery-company/agents')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: await AuthHelper.getAuthHeaders());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _mapAgents = List<Map<String, dynamic>>.from(body['data']);
        }
      } else {
        _mapAgentsError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
      }
    } catch (e) {
      _mapAgentsError = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _mapAgentsLoading = false;
      notifyListeners();
    }
  }

  void updateAgentLocation(int agentId, double lat, double lng) {
    final idx = _mapAgents.indexWhere((a) => a['id'] == agentId);
    if (idx != -1) {
      _mapAgents[idx] = {
        ..._mapAgents[idx],
        'current_latitude': lat,
        'current_longitude': lng,
        'last_location_update': DateTime.now().toIso8601String(),
      };
      notifyListeners();
    }
  }

  // --- Orders ---
  List<Map<String, dynamic>> _orders = [];
  bool _ordersLoading = false;
  String? _ordersError;

  List<Map<String, dynamic>> get orders => _orders;
  bool get ordersLoading => _ordersLoading;
  String? get ordersError => _ordersError;

  Future<void> loadOrders({String? status}) async {
    _ordersLoading = true;
    _ordersError = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/api/delivery-company/orders').replace(
        queryParameters: status != null ? {'status': status} : null,
      );
      final res = await http.get(uri, headers: await AuthHelper.getAuthHeaders());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          if (data is Map && data.containsKey('data')) {
            _orders = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is List) {
            _orders = List<Map<String, dynamic>>.from(data);
          }
        }
      } else {
        _ordersError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
      }
    } catch (e) {
      _ordersError = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _ordersLoading = false;
      notifyListeners();
    }
  }

  // --- Pending orders (shipped, no agent assigned) ---
  List<Map<String, dynamic>> _pendingOrders = [];
  bool _pendingOrdersLoading = false;
  String? _pendingOrdersError;

  List<Map<String, dynamic>> get pendingOrders => _pendingOrders;
  bool get pendingOrdersLoading => _pendingOrdersLoading;
  String? get pendingOrdersError => _pendingOrdersError;

  Future<void> loadPendingOrders() async {
    _pendingOrdersLoading = true;
    _pendingOrdersError = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/delivery-company/orders/pending'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          if (data is Map && data.containsKey('data')) {
            _pendingOrders = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is List) {
            _pendingOrders = List<Map<String, dynamic>>.from(data);
          } else {
            _pendingOrders = [];
          }
        } else {
          _pendingOrders = [];
        }
      } else {
        _pendingOrdersError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
        _pendingOrders = [];
      }
    } catch (e) {
      _pendingOrdersError = ErrorHandler.getUserFriendlyMessage(e);
      _pendingOrders = [];
    } finally {
      _pendingOrdersLoading = false;
      notifyListeners();
    }
  }

  // --- Available agents for an order (to assign) ---
  List<Map<String, dynamic>> _availableAgentsForOrder = [];
  bool _availableAgentsLoading = false;
  String? _availableAgentsError;

  List<Map<String, dynamic>> get availableAgentsForOrder => _availableAgentsForOrder;
  bool get availableAgentsLoading => _availableAgentsLoading;
  String? get availableAgentsError => _availableAgentsError;

  Future<void> loadAvailableAgentsForOrder(int orderId) async {
    _availableAgentsLoading = true;
    _availableAgentsError = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/delivery-company/orders/$orderId/available-agents'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _availableAgentsForOrder = List<Map<String, dynamic>>.from(body['data']);
        } else {
          _availableAgentsForOrder = [];
        }
      } else {
        _availableAgentsError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
        _availableAgentsForOrder = [];
      }
    } catch (e) {
      _availableAgentsError = ErrorHandler.getUserFriendlyMessage(e);
      _availableAgentsForOrder = [];
    } finally {
      _availableAgentsLoading = false;
      notifyListeners();
    }
  }

  /// Asignar orden a un agente.
  Future<bool> assignOrderToAgent(int orderId, int agentId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/delivery-company/orders/$orderId/assign'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'agent_id': agentId}),
      );
      if (res.statusCode == 200) {
        await loadPendingOrders();
        await loadOrders();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // --- Earnings ---
  Map<String, dynamic> _earningsData = {};
  bool _earningsLoading = false;
  String? _earningsError;

  Map<String, dynamic> get earningsData => _earningsData;
  bool get earningsLoading => _earningsLoading;
  String? get earningsError => _earningsError;

  Future<void> loadEarnings() async {
    _earningsLoading = true;
    _earningsError = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/delivery-company/earnings'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _earningsData = Map<String, dynamic>.from(body['data']);
        }
      } else {
        _earningsError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
      }
    } catch (e) {
      _earningsError = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _earningsLoading = false;
      notifyListeners();
    }
  }

  /// Crear agente (la empresa crea la cuenta del repartidor).
  Future<Map<String, dynamic>?> createAgent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String vehicleType,
    required String licenseNumber,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/delivery-company/agents'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'vehicle_type': vehicleType,
          'license_number': licenseNumber,
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 201 && body['success'] == true) {
        await loadAgents();
        return body['data'] != null ? Map<String, dynamic>.from(body['data']) : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Actualizar estado del agente (activo, inactivo, suspendido).
  Future<bool> updateAgentStatus(int agentId, String status) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/api/delivery-company/agents/$agentId'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );
      if (res.statusCode == 200) {
        await loadAgents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Actualizar porcentaje de pago del agente (0-100).
  Future<bool> updateAgentPayout(int agentId, double payoutPercentage) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/api/delivery-company/agents/$agentId/payout'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'payout_percentage': payoutPercentage.clamp(0.0, 100.0)}),
      );
      if (res.statusCode == 200) {
        await loadAgents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // --- Pending payment orders (delivery payment proof uploaded, not validated) ---
  List<Map<String, dynamic>> _pendingPaymentOrders = [];
  bool _pendingPaymentOrdersLoading = false;
  String? _pendingPaymentOrdersError;

  List<Map<String, dynamic>> get pendingPaymentOrders => _pendingPaymentOrders;
  bool get pendingPaymentOrdersLoading => _pendingPaymentOrdersLoading;
  String? get pendingPaymentOrdersError => _pendingPaymentOrdersError;

  Future<void> loadPendingPaymentOrders() async {
    _pendingPaymentOrdersLoading = true;
    _pendingPaymentOrdersError = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/delivery-company/orders/pending-payment'),
        headers: await AuthHelper.getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          if (data is Map && data.containsKey('data')) {
            _pendingPaymentOrders = List<Map<String, dynamic>>.from(data['data']);
          } else if (data is List) {
            _pendingPaymentOrders = List<Map<String, dynamic>>.from(data);
          } else {
            _pendingPaymentOrders = [];
          }
        }
      } else {
        _pendingPaymentOrdersError = ErrorHandler.handleHttpResponse(res.statusCode, res.body);
      }
    } catch (e) {
      _pendingPaymentOrdersError = ErrorHandler.getUserFriendlyMessage(e);
    } finally {
      _pendingPaymentOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateDeliveryPayment(int orderId, bool isValid, {String? rejectionReason}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/delivery-company/orders/$orderId/validate-delivery-payment'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'is_valid': isValid,
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        }),
      );
      if (res.statusCode == 200) {
        await loadPendingPaymentOrders();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Actualizar configuración de la empresa (ej. porcentaje default para nuevos agentes).
  Future<bool> updateCompanySettings({double? defaultPayoutPercentage}) async {
    try {
      final body = <String, dynamic>{};
      if (defaultPayoutPercentage != null) body['default_payout_percentage'] = defaultPayoutPercentage.clamp(0.0, 100.0);
      if (body.isEmpty) return true;
      final res = await http.patch(
        Uri.parse('$_baseUrl/api/delivery-company/settings'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        await loadDashboard();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
