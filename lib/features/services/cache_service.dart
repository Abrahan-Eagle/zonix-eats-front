import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class CacheService {
  static final Logger _logger = Logger();
  static const String _cachePrefix = 'zonix_cache_';
  static const Duration _defaultExpiration = Duration(hours: 1);
  
  // Cache keys
  static const String restaurantsKey = 'restaurants';
  static const String productsKey = 'products';
  static const String userProfileKey = 'user_profile';
  static const String cartKey = 'cart';
  static const String ordersKey = 'orders';
  static const String categoriesKey = 'categories';
  
  /// Get cached data
  static Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = data['timestamp'] as int?;
        final expiration = data['expiration'] as int?;
        
        if (timestamp != null && expiration != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - timestamp < expiration) {
            _logger.i('Cache hit for key: $key');
            return fromJson(data['data']);
          } else {
            _logger.i('Cache expired for key: $key');
            await remove(key);
          }
        }
      }
      
      _logger.i('Cache miss for key: $key');
      return null;
    } catch (e) {
      _logger.e('Error getting cache for key: $key', error: e);
      return null;
    }
  }
  
  /// Set cached data
  static Future<void> set<T>(
    String key,
    T data,
    T Function(T) toJson, {
    Duration expiration = _defaultExpiration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cacheData = {
        'data': toJson(data),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiration': expiration.inMilliseconds,
      };
      
      await prefs.setString(cacheKey, json.encode(cacheData));
      _logger.i('Cache set for key: $key with expiration: ${expiration.inMinutes} minutes');
    } catch (e) {
      _logger.e('Error setting cache for key: $key', error: e);
    }
  }
  
  /// Remove cached data
  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      await prefs.remove(cacheKey);
      _logger.i('Cache removed for key: $key');
    } catch (e) {
      _logger.e('Error removing cache for key: $key', error: e);
    }
  }
  
  /// Clear all cache
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      _logger.i('All cache cleared');
    } catch (e) {
      _logger.e('Error clearing cache', error: e);
    }
  }
  
  /// Get cache size
  static Future<int> getSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      return cacheKeys.length;
    } catch (e) {
      _logger.e('Error getting cache size', error: e);
      return 0;
    }
  }
  
  /// Check if cache exists and is valid
  static Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = data['timestamp'] as int?;
        final expiration = data['expiration'] as int?;
        
        if (timestamp != null && expiration != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          return now - timestamp < expiration;
        }
      }
      
      return false;
    } catch (e) {
      _logger.e('Error checking cache existence for key: $key', error: e);
      return false;
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      
      int totalItems = 0;
      int expiredItems = 0;
      int validItems = 0;
      
      for (final key in cacheKeys) {
        totalItems++;
        final cachedData = prefs.getString(key);
        
        if (cachedData != null) {
          try {
            final data = json.decode(cachedData);
            final timestamp = data['timestamp'] as int?;
            final expiration = data['expiration'] as int?;
            
            if (timestamp != null && expiration != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - timestamp < expiration) {
                validItems++;
              } else {
                expiredItems++;
              }
            }
          } catch (e) {
            expiredItems++;
          }
        }
      }
      
      return {
        'total_items': totalItems,
        'valid_items': validItems,
        'expired_items': expiredItems,
        'cache_hit_rate': totalItems > 0 ? (validItems / totalItems) : 0.0,
      };
    } catch (e) {
      _logger.e('Error getting cache stats', error: e);
      return {
        'total_items': 0,
        'valid_items': 0,
        'expired_items': 0,
        'cache_hit_rate': 0.0,
      };
    }
  }
  
  /// Clean expired cache items
  static Future<void> cleanExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      
      int removedCount = 0;
      
      for (final key in cacheKeys) {
        final cachedData = prefs.getString(key);
        
        if (cachedData != null) {
          try {
            final data = json.decode(cachedData);
            final timestamp = data['timestamp'] as int?;
            final expiration = data['expiration'] as int?;
            
            if (timestamp != null && expiration != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - timestamp >= expiration) {
                await prefs.remove(key);
                removedCount++;
              }
            }
          } catch (e) {
            await prefs.remove(key);
            removedCount++;
          }
        }
      }
      
      _logger.i('Cleaned $removedCount expired cache items');
    } catch (e) {
      _logger.e('Error cleaning expired cache', error: e);
    }
  }
}

// Cache helper for specific data types
class CacheHelper {
  /// Cache restaurants with automatic JSON conversion
  static Future<List<Map<String, dynamic>>?> getRestaurants() async {
    return CacheService.get<List<Map<String, dynamic>>>(
      CacheService.restaurantsKey,
      (data) {
        if (data is List) {
          final list = data as List;
          return List<Map<String, dynamic>>.from(
            list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          );
        } else if (data is Map) {
          return [Map<String, dynamic>.from(data as Map)];
        }
        return <Map<String, dynamic>>[];
      },
    );
  }
  
  static Future<void> setRestaurants(List<Map<String, dynamic>> restaurants) async {
    await CacheService.set<List<Map<String, dynamic>>>(
      CacheService.restaurantsKey,
      restaurants,
      (data) => data,
      expiration: const Duration(minutes: 30),
    );
  }
  
  /// Cache products with automatic JSON conversion
  static Future<List<Map<String, dynamic>>?> getProducts() async {
    return CacheService.get<List<Map<String, dynamic>>>(
      CacheService.productsKey,
      (data) {
        if (data is List) {
          final list = data as List;
          return List<Map<String, dynamic>>.from(
            list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          );
        } else if (data is Map) {
          return [Map<String, dynamic>.from(data as Map)];
        }
        return <Map<String, dynamic>>[];
      },
    );
  }
  
  static Future<void> setProducts(List<Map<String, dynamic>> products) async {
    await CacheService.set<List<Map<String, dynamic>>>(
      CacheService.productsKey,
      products,
      (data) => data,
      expiration: const Duration(minutes: 15),
    );
  }
  
  /// Cache user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    return CacheService.get<Map<String, dynamic>>(
      CacheService.userProfileKey,
      (data) => data,
    );
  }
  
  static Future<void> setUserProfile(Map<String, dynamic> profile) async {
    await CacheService.set<Map<String, dynamic>>(
      CacheService.userProfileKey,
      profile,
      (data) => data,
      expiration: const Duration(hours: 2),
    );
  }
  
  /// Cache cart
  static Future<List<Map<String, dynamic>>?> getCart() async {
    return CacheService.get<List<Map<String, dynamic>>>(
      CacheService.cartKey,
      (data) {
        if (data is List) {
          final list = data as List;
          return List<Map<String, dynamic>>.from(
            list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          );
        } else if (data is Map) {
          return [Map<String, dynamic>.from(data as Map)];
        }
        return <Map<String, dynamic>>[];
      },
    );
  }
  
  static Future<void> setCart(List<Map<String, dynamic>> cart) async {
    await CacheService.set<List<Map<String, dynamic>>>(
      CacheService.cartKey,
      cart,
      (data) => data,
      expiration: const Duration(hours: 24),
    );
  }
} 