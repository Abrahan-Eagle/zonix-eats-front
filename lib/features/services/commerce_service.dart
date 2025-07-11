import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommerceService {
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

  Future<bool> userHasCommerce(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/commerces/user/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Suponemos que si data no es null, el usuario tiene comercio
      return data != null;
    }
    return false;
  }
} 