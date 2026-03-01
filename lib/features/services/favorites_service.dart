import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class FavoritesService {
  // GET /api/buyer/favorites - Obtener favoritos del usuario
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/favorites');
      
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener favoritos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  // POST /api/buyer/posts/{id}/favorite - Agregar/remover de favoritos
  Future<Map<String, dynamic>> toggleFavorite(int postId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/posts/$postId/favorite');
      
      final response = await http.post(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'is_favorite': data['is_favorite'] ?? false,
            'message': data['message'] ?? 'Favorito actualizado',
          };
        } else {
          throw Exception(data['message'] ?? 'Error al actualizar favorito');
        }
      } else {
        throw Exception('Error al actualizar favorito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar favorito: $e');
    }
  }

  // Verificar si un post está en favoritos
  Future<bool> isFavorite(int postId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((favorite) => favorite['id'] == postId);
    } catch (e) {
      return false;
    }
  }

  // Obtener cantidad de favoritos
  Future<int> getFavoritesCount() async {
    try {
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      return 0;
    }
  }

  // Buscar en favoritos
  Future<List<Map<String, dynamic>>> searchFavorites(String query) async {
    try {
      final favorites = await getFavorites();
      return favorites.where((favorite) {
        final name = favorite['name']?.toString().toLowerCase() ?? '';
        final description = favorite['description']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }
} 