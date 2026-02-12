import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();
final GoogleSignIn _googleSignIn = GoogleSignIn();
final Logger logger = Logger();
final ApiService _apiService = ApiService();

class GoogleSignInService {
  // Método para iniciar sesión con Google
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        logger.i('Inicio de sesión cancelado');
        return null; // Retorna null si el usuario cancela la autenticación
      }

      final googleAuth = await user.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      if (accessToken == null && idToken == null) {
        logger.e('Error: Tanto el accessToken como el idToken son null');
        return null; // Retorna null si no hay ni accessToken ni idToken
      }

      // Guardar tokens de Google
      if (accessToken != null) {
        await AuthUtils.saveToken(accessToken, 3600); // Ajusta el tiempo de expiración
      }
      if (idToken != null) {
        await _storage.write(key: 'google_idToken', value: idToken);
      }

      // Obtener datos del perfil del usuario utilizando el accessToken
      final profileResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {
          'Authorization': 'Bearer ${accessToken ?? idToken}',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        logger.i('Datos del perfil de usuario: ${jsonEncode(profileData)}');

        // Enviar el token al backend
        final processedResult = jsonEncode({
          'token': accessToken ?? idToken,
          'profile': profileData,
        });

        final response = await _apiService.sendTokenToBackend(processedResult);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>?;
          if (data == null) {
            logger.e('Backend devolvió respuesta vacía');
            return null;
          }
          final token = data['token']?.toString();
          final expiresIn = data['expires_in'] is int ? data['expires_in'] as int : (int.tryParse(data['expires_in']?.toString() ?? '0') ?? 3600);
          if (token == null || token.isEmpty) {
            logger.e('Backend no devolvió token');
            return null;
          }
          await AuthUtils.saveToken(token, expiresIn);
          final role = data['user']?['role']?.toString() ?? 'users';
          await _storage.write(key: 'role', value: role);
          logger.i('Token guardado correctamente con su expiración.');
          return user; // Retorna el usuario autenticado
        } else {
          logger.e('Error al enviar el token al backend: ${response.statusCode}');
          return null; // Retorna null si hay error al enviar el token al backend
        }
      } else {
        logger.e('Error al obtener los datos del perfil: ${profileResponse.statusCode}');
        return null; // Retorna null si no se pueden obtener los datos del perfil
      }
    } catch (error) {
      logger.e('Error durante el inicio de sesión con Google: $error');
      return null; // Retorna null si hay una excepción
    }
  }

  // Método para obtener el usuario autenticado actualmente
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      if (user != null) {
        logger.i('Usuario actualmente autenticado: ${user.email}');
        return user; // Devuelve el usuario autenticado directamente
      } else {
        logger.i('No hay usuario autenticado actualmente.');
      }
    } catch (error) {
      logger.e('Error al intentar autenticar de forma silenciosa: $error');
      return null;
    }
    return null; // Devuelve null si no hay usuario autenticado
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storage.deleteAll(); // Eliminar los tokens almacenados
      logger.i('Sesión cerrada exitosamente.');
    } catch (error) {
      logger.e('Error al cerrar sesión: $error');
    }
  }

  // Inicialización: Verifica si hay un usuario autenticado silenciosamente al iniciar la app
  Future<void> initAuth() async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      logger.i('Usuario autenticado automáticamente: ${currentUser.email}');
    } else {
      logger.i('No se detectó ningún usuario autenticado. Requiere inicio de sesión.');
    }
  }
}
