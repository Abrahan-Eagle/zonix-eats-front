import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';

class DeliveryCompanyService {

  Future<bool> userHasDeliveryCompany(int userId) async {
    final response = await http.get(Uri.parse('${AppConfig.apiUrl}/api/delivery_companies/user/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Suponemos que si data no es null, el usuario tiene empresa de delivery
      return data != null;
    }
    return false;
  }
} 