import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class AuthService {
  static const storage = FlutterSecureStorage();
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // POST /api/auth/login - Login de usuario
  Future<Map<String, dynamic>> login(String email, String password) async {
    logger.i('Attempting login for: $email');
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      logger.i('Login Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final userData = data['data'];
          final token = userData['token'];
          
          // Guardar el token
          await storage.write(key: 'token', value: token);
          await storage.write(key: 'user', value: jsonEncode(userData['user']));
          
          logger.i('Login successful, token saved');
          return {
            'success': true,
            'user': userData['user'],
            'token': token,
          };
        } else {
          logger.e('Login failed: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Login failed',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        logger.e('Login error: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e, stack) {
      logger.e('Exception in login', error: e, stackTrace: stack);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // GET /api/auth/user - Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/auth/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      logger.e('Error getting current user: $e');
      return null;
    }
  }

  // POST /api/auth/logout - Logout
  Future<bool> logout() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return true;

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      // Limpiar almacenamiento local
      await storage.delete(key: 'token');
      await storage.delete(key: 'user');
      
      logger.i('Logout successful');
      return true;
    } catch (e) {
      logger.e('Error during logout: $e');
      // Limpiar almacenamiento local incluso si hay error
      await storage.delete(key: 'token');
      await storage.delete(key: 'user');
      return true;
    }
  }

  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }

  // Obtener token almacenado
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
} 