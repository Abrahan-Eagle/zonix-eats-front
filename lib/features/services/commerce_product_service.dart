import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/commerce_product.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class CommerceProductService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String get baseUrl => AppConfig.apiUrl;

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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (available != null) queryParams['available'] = available.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      final uri = Uri.parse('${baseUrl}/api/commerce/products').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/api/commerce/products/$id'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}/api/commerce/products'),
      );
      request.headers.addAll(headers);

      // Solo enviar los campos requeridos y con el nombre correcto
      final allowedFields = ['name', 'description', 'price', 'available', 'stock', 'category_id'];
      for (final key in allowedFields) {
        if (data[key] != null) {
          if (key == 'price') {
            final priceValue = data[key];
            request.fields[key] = priceValue is num
                ? priceValue.toString()
                : double.tryParse(priceValue.toString().replaceAll(RegExp(r'[^0-9\.]'), ''))?.toString() ?? '0';
          } else if (key == 'available') {
            request.fields[key] = (data[key] is bool)
                ? (data[key] ? '1' : '0')
                : data[key].toString();
          } else {
            request.fields[key] = data[key].toString();
          }
        }
      }

      // Agregar imagen si existe (campo 'image')
      if (imageFile != null) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'image',
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
        String errorMsg = 'Error al crear producto: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) errorMsg += '\n${errorData['message']}';
          if (errorData['errors'] != null) errorMsg += '\n${errorData['errors'].toString()}';
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // Actualizar producto
  static Future<CommerceProduct> updateProduct(int id, Map<String, dynamic> data, {File? imageFile}) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}/api/commerce/products/$id'),
      );
      request.headers.addAll(headers);
      request.fields['_method'] = 'PUT';

      final allowedFields = ['name', 'description', 'price', 'available', 'stock', 'category_id'];
      for (final key in allowedFields) {
        if (data[key] != null) {
          if (key == 'price') {
            final priceValue = data[key];
            request.fields[key] = priceValue is num
                ? priceValue.toString()
                : double.tryParse(priceValue.toString().replaceAll(RegExp(r'[^0-9\.]'), ''))?.toString() ?? '0';
          } else if (key == 'available') {
            request.fields[key] = (data[key] is bool)
                ? (data[key] ? '1' : '0')
                : data[key].toString();
          } else {
            request.fields[key] = data[key].toString();
          }
        }
      }

      // Agregar imagen si existe (campo 'image')
      if (imageFile != null) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'image',
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
        String errorMsg = 'Error al actualizar producto: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) errorMsg += '\n${errorData['message']}';
          if (errorData['errors'] != null) errorMsg += '\n${errorData['errors'].toString()}';
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // Eliminar producto
  static Future<void> deleteProduct(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}/api/commerce/products/$id'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}/api/commerce/products/$id/toggle-disponible'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/api/commerce/products-stats'),
        headers: headers,
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}/api/commerce/products/upload-image'),
      );

      request.headers.addAll(headers);

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

  // Obtener categorías de productos desde el endpoint real
  static Future<List<Map<String, dynamic>>> getProductCategories() async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final url = Uri.parse('${baseUrl}/api/buyer/search/categories');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }
} 