import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commerce_product.dart';
import '../config/app_config.dart';
import '../helpers/auth_helper.dart';

class CommerceProductService {
  final String apiUrl = '${AppConfig.apiUrl}/api/commerce/products';

  Future<List<CommerceProduct>> fetchProducts() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(Uri.parse(apiUrl), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productsData = data['data'] is List ? data['data'] : [];
      return productsData.map((item) => CommerceProduct.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar productos: ${response.statusCode}');
    }
  }

  Future<CommerceProduct> createProduct(Map<String, dynamic> data) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.post(Uri.parse(apiUrl), headers: headers, body: data);
    if (response.statusCode == 201) {
      final product = json.decode(response.body)['data'];
      return CommerceProduct.fromJson(product);
    } else {
      throw Exception('Error al crear producto');
    }
  }

  Future<CommerceProduct> updateProduct(int id, Map<String, dynamic> data) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.put(Uri.parse('$apiUrl/$id'), headers: headers, body: data);
    if (response.statusCode == 200) {
      final product = json.decode(response.body)['data'];
      return CommerceProduct.fromJson(product);
    } else {
      throw Exception('Error al actualizar producto');
    }
  }

  Future<void> deleteProduct(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.delete(Uri.parse('$apiUrl/$id'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }

  Future<void> toggleAvailable(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.put(Uri.parse('$apiUrl/$id/toggle-disponible'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error al cambiar disponibilidad');
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(Uri.parse('${AppConfig.apiUrl}/api/commerce/products-stats'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {};
    } else {
      throw Exception('Error al obtener estadísticas');
    }
  }
} 