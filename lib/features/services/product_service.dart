import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'package:zonix/config/app_config.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import '../utils/http_retry.dart';

final Logger _logger = Logger();

class BuyerProductsPageResult {
  const BuyerProductsPageResult({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Product> products;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

class ProductService {
  final String apiUrl = '${AppConfig.apiUrl}/api/buyer/products';

  static const String _cacheKey = 'products_list';

  /// Returns cached product list instantly (even if expired) for stale-while-revalidate.
  static Future<List<Product>?> getCachedProducts() async {
    final cached = await CacheService.getRawJson(_cacheKey);
    if (cached == null) return null;
    final list = json.decode(cached) as List;
    return list.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList();
  }

  BuyerProductsPageResult _parseProductsPageResult(
    dynamic data, {
    required int fallbackPage,
  }) {
    List<dynamic> productsData = [];
    int currentPage = fallbackPage;
    int lastPage = fallbackPage;
    int total = 0;

    if (data is Map && data['success'] == true && data['data'] != null) {
      final payload = data['data'];
      if (payload is List) {
        productsData = payload;
      } else if (payload is Map) {
        if (payload['items'] is List) {
          productsData = payload['items'] as List;
        } else if (payload['data'] is List) {
          productsData = payload['data'] as List;
        } else if (payload['products'] is List) {
          productsData = payload['products'] as List;
        }

        currentPage = (payload['current_page'] as num?)?.toInt() ?? currentPage;
        lastPage = (payload['last_page'] as num?)?.toInt() ?? lastPage;
        total = (payload['total'] as num?)?.toInt() ?? total;

        final pagination = payload['pagination'];
        if (pagination is Map) {
          currentPage = (pagination['current_page'] as num?)?.toInt() ?? currentPage;
          lastPage = (pagination['last_page'] as num?)?.toInt() ?? lastPage;
          total = (pagination['total'] as num?)?.toInt() ?? total;
        }
      }
    } else {
      productsData = data is List ? data : [];
    }

    final products = productsData
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();

    if (total == 0) {
      total = products.length;
    }

    return BuyerProductsPageResult(
      products: products,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  Future<BuyerProductsPageResult> fetchProductsPage({
    required int page,
    int perPage = 20,
    int? categoryId,
  }) async {
    if (!ConnectivityService.isConnected && categoryId == null) {
      final cached = await CacheService.getRawJson(_cacheKey);
      if (cached != null && page == 1) {
        final list = (json.decode(cached) as List).map((j) => Product.fromJson(j)).toList();
        return BuyerProductsPageResult(
          products: list,
          currentPage: 1,
          lastPage: 1,
          total: list.length,
        );
      }
    }

    final headers = await AuthHelper.getAuthHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }
    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logger.i('Llamando a $url');

    try {
      final response = await withRetry(() => http.get(uri, headers: headers));
      _logger.i('Status code:  ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = _parseProductsPageResult(data, fallbackPage: page);
        _logger.i('Cantidad de productos recibidos: ${result.products.length}');
        if (categoryId == null && page == 1) {
          CacheService.setRawJson(
            _cacheKey,
            jsonEncode(result.products.map((p) => p.toJson()).toList()),
            expiration: const Duration(hours: 2),
          );
        }
        return result;
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('fetchProducts network error, trying cache');
      if (categoryId == null && page == 1) {
        final cached = await CacheService.getRawJson(_cacheKey);
        if (cached != null) {
          final list = json.decode(cached) as List;
          final products = list.map((j) => Product.fromJson(j)).toList();
          return BuyerProductsPageResult(
            products: products,
            currentPage: 1,
            lastPage: 1,
            total: products.length,
          );
        }
      }
      rethrow;
    }
  }

  Future<List<Product>> fetchProducts({int? categoryId}) async {
    final result = await fetchProductsPage(
      page: 1,
      perPage: 50,
      categoryId: categoryId,
    );
    return result.products;
  }

  // GET /api/buyer/search/products?commerce_id=... - Productos por comercio con filtros backend
  Future<List<Product>> fetchProductsByCommerce(int commerceId) async {
    final firstPage = await fetchSearchProductsPage(
      page: 1,
      perPage: 100,
      commerceId: commerceId,
    );
    return firstPage.products;
  }

  Future<BuyerProductsPageResult> fetchProductsByCommercePage({
    required int commerceId,
    required int page,
    int perPage = 20,
    String? search,
  }) async {
    return fetchSearchProductsPage(
      page: page,
      perPage: perPage,
      commerceId: commerceId,
      search: search,
    );
  }

  Future<BuyerProductsPageResult> fetchSearchProductsPage({
    required int page,
    int perPage = 20,
    String? search,
    int? commerceId,
    int? categoryId,
    bool? available,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (commerceId != null) {
      query['commerce_id'] = commerceId.toString();
    }
    if (categoryId != null) {
      query['category_id'] = categoryId.toString();
    }
    if (available != null) {
      query['available'] = available.toString();
    }

    final uri = Uri.parse('${AppConfig.apiUrl}/api/buyer/search/products')
        .replace(queryParameters: query);
    final response = await withRetry(() => http.get(uri, headers: headers));
    if (response.statusCode != 200) {
      throw Exception('Error al buscar productos: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return _parseProductsPageResult(data, fallbackPage: page);
  }

  // GET /api/buyer/products/{id} - Obtener producto por ID
  Future<Product> getProductById(int productId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = '$apiUrl/$productId';
    _logger.i('Llamando a $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    
    _logger.i('Status code: ${response.statusCode}');
    if (kDebugMode) {
      _logger.d('getProductById payload length: ${response.body.length}');
    }
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        _logger.d('Decoded data type: ${data.runtimeType}');
      }
      
      // Handle different response structures
      Map<String, dynamic> productData;
      
      if (data is Map<String, dynamic>) {
        // Check if it's wrapped in success/data structure
        if (data['success'] == true && data['data'] != null) {
          productData = data['data'];
        } else {
          // Direct product object
          productData = data;
        }
      } else if (data is List && data.isNotEmpty) {
        // If backend returns an array, take the first item
        _logger.w('Backend returned array instead of object, taking first item');
        productData = data[0];
      } else {
        throw Exception('Invalid response format from backend');
      }
      
      return Product.fromJson(productData);
    } else {
      _logger.e('Error al cargar producto: ${response.statusCode}');
      if (kDebugMode) {
        _logger.e('Error payload length: ${response.body.length}');
      }
      throw Exception('Error al cargar producto: ${response.statusCode}');
    }
  }
}
