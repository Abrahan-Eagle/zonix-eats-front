import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';
import 'package:zonix/helpers/auth_helper.dart';

class DisputeService {
  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'in_review':
        return 'En revisión';
      case 'resolved':
        return 'Resuelta';
      case 'closed':
        return 'Cerrada';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  static String typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'payment_issue':
        return 'Problema de pago';
      case 'delivery_problem':
        return 'Problema de entrega';
      case 'quality_issue':
        return 'Problema de calidad';
      case 'other':
        return 'Otro';
      default:
        return type.isEmpty ? '—' : type;
    }
  }

  Future<Map<String, dynamic>> getBuyerDisputes({int page = 1, int perPage = 15}) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse(
      '${AppConfig.apiUrl}/api/buyer/disputes?page=$page&per_page=$perPage',
    );
    final response = await http.get(url, headers: headers);
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('No se pudieron cargar las disputas');
    }
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'No se pudieron cargar las disputas').toString());
    }

    final data = body['data'] is List ? List<Map<String, dynamic>>.from(body['data']) : <Map<String, dynamic>>[];
    final pagination = body['pagination'] is Map<String, dynamic>
        ? body['pagination'] as Map<String, dynamic>
        : <String, dynamic>{};

    return {
      'items': data,
      'pagination': pagination,
    };
  }

  Future<Map<String, dynamic>> createDispute({
    required int orderId,
    required String type,
    required String description,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/disputes');
    final response = await http.post(
      url,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'order_id': orderId,
        'type': type,
        'description': description,
      }),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if ((response.statusCode == 200 || response.statusCode == 201) && body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(body['data']);
      }
    }

    if (body is Map<String, dynamic>) {
      final msg = body['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        throw Exception(msg);
      }
    }
    throw Exception('No se pudo crear la disputa');
  }

  Future<Map<String, dynamic>> getDisputeById(int disputeId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/disputes/$disputeId');
    final response = await http.get(url, headers: headers);
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(body['data']);
      }
    }

    if (body is Map<String, dynamic>) {
      final msg = body['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        throw Exception(msg);
      }
    }
    throw Exception('No se pudo cargar la disputa');
  }
}
