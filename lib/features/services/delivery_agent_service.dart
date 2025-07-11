import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeliveryAgentService {
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

  Future<bool> userHasDeliveryAgent(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/delivery_agents/user/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Suponemos que si data no es null, el usuario es repartidor
      return data != null;
    }
    return false;
  }
} 