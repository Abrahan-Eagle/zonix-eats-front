import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commerce_profile.dart';
import '../config/app_config.dart';
import '../helpers/auth_helper.dart';

class CommerceProfileService {
  final String apiUrl = '${AppConfig.baseUrl}/api/profile';

  Future<CommerceProfile> fetchProfile() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(Uri.parse(apiUrl), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CommerceProfile.fromJson(data is Map ? data : data['data']);
    } else {
      throw Exception('Error al cargar perfil');
    }
  }

  Future<CommerceProfile> updateProfile(Map<String, dynamic> data) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.put(Uri.parse(apiUrl), headers: headers, body: data);
    if (response.statusCode == 200) {
      final updated = json.decode(response.body);
      return CommerceProfile.fromJson(updated is Map ? updated : updated['data']);
    } else {
      throw Exception('Error al actualizar perfil');
    }
  }
} 