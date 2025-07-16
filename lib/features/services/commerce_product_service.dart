import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/commerce_product.dart';

class CommerceProductService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String baseUrl = 'http://192.168.0.102:8000/api';

  // Obtener todos los productos del comercio
  static Future<List<CommerceProduct>> getProducts({
    String? search,
    bool? available,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (available != null) queryParams['available'] = available.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      final uri = Uri.parse('$baseUrl/commerce/products').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final productsData = data['data'];
          if (productsData is List) {
            return productsData.map((json) => CommerceProduct.fromJson(json)).toList();
          } else if (productsData['data'] != null) {
            // Si es paginación
            return (productsData['data'] as List).map((json) => CommerceProduct.fromJson(json)).toList();
          }
        }
        return [];
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  // Obtener un producto específico
  static Future<CommerceProduct> getProduct(int id) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/products/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CommerceProduct.fromJson(data['data']);
        }
        throw Exception('Producto no encontrado');
      } else {
        throw Exception('Error al obtener producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  // Crear nuevo producto
  static Future<CommerceProduct> createProduct(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/commerce/products'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Agregar campos de texto
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Agregar imagen si existe
      if (imageFile != null) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'imagen',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CommerceProduct.fromJson(data['data']);
        }
        throw Exception('Error al crear producto');
      } else {
        throw Exception('Error al crear producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // Actualizar producto
  static Future<CommerceProduct> updateProduct(int id, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      var request = http.MultipartRequest(
        'POST', // Laravel usa POST para actualizar con archivos
        Uri.parse('$baseUrl/commerce/products/$id'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Agregar método PUT
      request.fields['_method'] = 'PUT';

      // Agregar campos de texto
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Agregar imagen si existe
      if (imageFile != null) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'imagen',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CommerceProduct.fromJson(data['data']);
        }
        throw Exception('Error al actualizar producto');
      } else {
        throw Exception('Error al actualizar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // Eliminar producto
  static Future<void> deleteProduct(int id) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.delete(
        Uri.parse('$baseUrl/commerce/products/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // Cambiar disponibilidad del producto
  static Future<CommerceProduct> toggleAvailability(int id) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/commerce/products/$id/toggle-disponible'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CommerceProduct.fromJson(data['data']);
        }
        throw Exception('Error al cambiar disponibilidad');
      } else {
        throw Exception('Error al cambiar disponibilidad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cambiar disponibilidad: $e');
    }
  }

  // Obtener estadísticas de productos
  static Future<Map<String, dynamic>> getProductStats() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/products-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
        return {};
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Subir imagen de producto
  static Future<String> uploadProductImage(File imageFile) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/commerce/products/upload-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['image_url'] ?? '';
      } else {
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }
} 