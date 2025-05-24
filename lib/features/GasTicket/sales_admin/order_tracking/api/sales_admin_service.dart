import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

class ApiService {
   final String apiUrl = '$baseUrl/api/sales-admin/tickets';
  final storage = const FlutterSecureStorage(); // Instancia de almacenamiento seguro

  // Método para recuperar el token almacenado
  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }


  // Verificar ticket
  Future<Map<String, dynamic>> verifyTicket(int id) async {
    String? token = await _getToken();

    if (token == null) {
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

    final response = await http.post(
      Uri.parse('$apiUrl/$id/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify ticket');
    }
  }

  // Marcar ticket como esperando
  Future<Map<String, dynamic>> markAsWaiting(int id) async {

    String? token = await _getToken();

    if (token == null) {
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

    final response = await http.post(
      Uri.parse('$apiUrl/$id/waiting'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark ticket as waiting');
    }
  }

  // Cancelar ticket
  Future<Map<String, dynamic>> cancelTicket(int id) async {

    String? token = await _getToken();

    if (token == null) {
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

    final response = await http.post(
      Uri.parse('$apiUrl/$id/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to cancel ticket');
    }
  }
}