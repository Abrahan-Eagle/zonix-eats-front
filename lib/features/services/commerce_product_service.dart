import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/commerce_product.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

/// Resultado paginado de productos (para "cargar más").
class ProductsPageResult {
  const ProductsPageResult({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  final List<CommerceProduct> products;
  final int currentPage;
  final int lastPage;
  final int total;
  bool get hasMore => currentPage < lastPage;
}

class CommerceProductService {
  static String get baseUrl => AppConfig.apiUrl;

  /// Obtener una página de productos (para listado con "cargar más").
  static Future<ProductsPageResult> getProductsPage({
    required int page,
    int perPage = 15,
    String? search,
    bool? available,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (available != null) queryParams['available'] = available.toString();
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;

    final uri = Uri.parse('$baseUrl/api/commerce/products').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener productos: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data['success'] != true || data['data'] == null) {
      return const ProductsPageResult(products: [], currentPage: 1, lastPage: 1, total: 0);
    }
    final list = data['data'] is List
        ? data['data'] as List
        : (data['data'] as Map)['data'] as List? ?? [];
    final pag = data['pagination'] as Map<String, dynamic>? ?? {};
    final products = list.map((json) => CommerceProduct.fromJson(json as Map<String, dynamic>)).toList();
    return ProductsPageResult(
      products: products,
      currentPage: (pag['current_page'] as num?)?.toInt() ?? page,
      lastPage: (pag['last_page'] as num?)?.toInt() ?? 1,
      total: (pag['total'] as num?)?.toInt() ?? products.length,
    );
  }

  // Obtener todos los productos del comercio (primera página; para compatibilidad).
  static Future<List<CommerceProduct>> getProducts({
    String? search,
    bool? available,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) async {
    final result = await getProductsPage(
      page: 1,
      perPage: perPage ?? 15,
      search: search,
      available: available,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    return result.products;
  }

  // Obtener un producto específico
  static Future<CommerceProduct> getProduct(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/products/$id'),
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
        Uri.parse('$baseUrl/api/commerce/products'),
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
        Uri.parse('$baseUrl/api/commerce/products/$id'),
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
        Uri.parse('$baseUrl/api/commerce/products/$id'),
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
        Uri.parse('$baseUrl/api/commerce/products/$id/toggle-disponible'),
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
        Uri.parse('$baseUrl/api/commerce/products-stats'),
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
        Uri.parse('$baseUrl/api/commerce/products/upload-image'),
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
      final url = Uri.parse('$baseUrl/api/buyer/search/categories');
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