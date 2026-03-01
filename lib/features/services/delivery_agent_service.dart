import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';

class DeliveryAgentService {

  Future<bool> userHasDeliveryAgent(int userId) async {
    final response = await http.get(Uri.parse('${AppConfig.apiUrl}/api/delivery_agents/user/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Suponemos que si data no es null, el usuario es repartidor
      return data != null;
    }
    return false;
  }
} 