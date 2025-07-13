import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final logger = Logger();
const FlutterSecureStorage _storage = FlutterSecureStorage(); // Inicializa _storage
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
class ApiService {
  // Enviar el token al backend
  Future<http.Response> sendTokenToBackend(String? result) async {
    if (result == null) {
      logger.e('Error: el data es null');
      throw Exception('El data es null'); // Lanza una excepción
    }

    final decodedData = jsonDecode(result); // Decodificar el JSON

    try {
      final body = jsonEncode({
        'success': true,
        'token': decodedData['token'],
        'data': decodedData['profile'],
        'message': 'Datos recibidos correctamente.',
      });

      final response = await http.post(
      Uri.parse( '$baseUrl/api/auth/google'), // Cambia por la URL de tu backend
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'flutter/1.0',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        logger.i('Respuesta del servidor: $responseData');
        
        // Handle the nested response structure: {success: true, data: {user: {...}, token: ...}}
        Map<String, dynamic> userData;
        String? token;
        
        if (responseData.containsKey('success') && responseData.containsKey('data')) {
          // New format: {success: true, data: {user: {...}, token: ...}}
          userData = responseData['data']['user'] ?? {};
          token = responseData['data']['token'] ?? responseData['token'];
        } else {
          // Fallback to old format: {user: {...}, token: ...}
          userData = responseData['user'] ?? {};
          token = responseData['token'];
        }
        
        var $varToken = token;
        logger.i($varToken);
        var $varRole = userData['role'];
        logger.i($varRole);
        var $completedOnboarding = userData['completed_onboarding']?.toString(); // Convertimos a String
        logger.i($completedOnboarding);

        // Verificación más flexible para data
        if ($varToken != null) {
          await _storage.write(key: 'token', value: $varToken);  // Guardar el JWT en almacenamiento seguro
          await _storage.write(key: 'role', value: $varRole);
          await _storage.write(key: 'userCompletedOnboarding', value: $completedOnboarding); // Guardamos como String

          logger.i('Inicio de sesión exitoso');

          // Leer el token del almacenamiento seguro
          String? token = await _storage.read(key: 'token');
          if (token != null) {
            logger.i('Token almacenado: $token');
          } else {
            logger.e('No se encontró ningún token almacenado');
          }

         // Leer el token del almacenamiento seguro
          String? role = await _storage.read(key: 'role');
          if (role != null) {
            logger.i('role almacenadoaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: $role');
          } else {
            logger.e('No se encontró ningún role almacenado');
          }

                    // Convertir a booleano al leer desde el almacenamiento
          bool storedOnboarding = (await _storage.read(key: 'userCompletedOnboarding')) == '1';
          logger.i('Estado de completedOnboarding almacenado: $storedOnboarding');

        } else {
          logger.e('Respuesta inesperada: ${response.body}');
        }
      } else {
        logger.e('Error al iniciar sesión en Laravel: ${response.statusCode} - ${response.body}');
      }

      return response; // Devuelve la respuesta
    } catch (error) {
      logger.e('Error: $error');
      throw Exception('Error en el envío de datos: $error'); // Lanza una excepción
    }
  }

  // Método para cerrar sesión
  Future<http.Response> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Método para enviar una solicitud autenticada
  Future<void> sendAuthenticatedRequest() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/protected-endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        logger.i("Datos recibidos: ${response.body}");
      } else if (response.statusCode == 401) {
        logger.e("Token expirado o inválido, redirigiendo a login");
        // Elimina el token almacenado y redirige al login
        await _storage.deleteAll();
        // Aquí puedes redirigir automáticamente al login
      } else {
        logger.e("Error en la solicitud: ${response.statusCode}");
      }
    } else {
      logger.e("No hay token almacenado");
    }
  }
}




// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:logger/logger.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// final logger = Logger();
// const FlutterSecureStorage _storage = FlutterSecureStorage(); // Inicializa _storage
// final String baseUrl = const bool.fromEnvironment('dart.vm.product')
//       ? dotenv.env['API_URL_PROD']!
//       : dotenv.env['API_URL_LOCAL']!;
// class ApiService {
//   // Enviar el token al backend
//   Future<http.Response> sendTokenToBackend(String? result) async {
//     if (result == null) {
//       logger.e('Error: el data es null');
//       throw Exception('El data es null'); // Lanza una excepción
//     }

//     final decodedData = jsonDecode(result); // Decodificar el JSON

//     try {
//       final body = jsonEncode({
//         'success': true,
//         'token': decodedData['token'],
//         'data': decodedData['profile'],
//         'message': 'Datos recibidos correctamente.',
//       });

//       final response = await http.post(
//       Uri.parse( '$baseUrl/api/auth/google'), // Cambia por la URL de tu backend
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'User-Agent': 'flutter/1.0',
//         },
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         logger.i('Respuesta del servidor: $responseData');
//         var $varToken = responseData['token'];
//         logger.i($varToken);
//         var $varRole= responseData['user']['role'];
//         logger.i($varRole);
//         var $completedOnboarding = responseData['user']['completed_onboarding']?.toString(); // Convertimos a String
//         logger.i($completedOnboarding);

//         // Verificación más flexible para data
//         if ($varToken != null) {
//           await _storage.write(key: 'token', value: responseData['token']);  // Guardar el JWT en almacenamiento seguro
//           await _storage.write(key: 'role', value: responseData['user']['role']);
//           await _storage.write(key: 'userCompletedOnboarding', value: $completedOnboarding); // Guardamos como String

//           logger.i('Inicio de sesión exitoso');

//           // Leer el token del almacenamiento seguro
//           String? token = await _storage.read(key: 'token');
//           if (token != null) {
//             logger.i('Token almacenado: $token');
//           } else {
//             logger.e('No se encontró ningún token almacenado');
//           }

//          // Leer el token del almacenamiento seguro
//           String? role = await _storage.read(key: 'role');
//           if (role != null) {
//             logger.i('role almacenadoaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: $role');
//           } else {
//             logger.e('No se encontró ningún role almacenado');
//           }

//                     // Convertir a booleano al leer desde el almacenamiento
//           bool storedOnboarding = (await _storage.read(key: 'userCompletedOnboarding')) == '1';
//           logger.i('Estado de completedOnboarding almacenado: $storedOnboarding');

//         } else {
//           logger.e('Respuesta inesperada: ${response.body}');
//         }
//       } else {
//         logger.e('Error al iniciar sesión en Laravel: ${response.statusCode} - ${response.body}');
//       }

//       return response; // Devuelve la respuesta
//     } catch (error) {
//       logger.e('Error: $error');
//       throw Exception('Error en el envío de datos: $error'); // Lanza una excepción
//     }
//   }

//   // Método para cerrar sesión
//   Future<http.Response> logout(String token) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/api/auth/logout'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//     return response;
//   }

//   // Método para enviar una solicitud autenticada
//   Future<void> sendAuthenticatedRequest() async {
//     final token = await _storage.read(key: 'token');
//     if (token != null) {
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/auth/protected-endpoint'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         logger.i("Datos recibidos: ${response.body}");
//       } else if (response.statusCode == 401) {
//         logger.e("Token expirado o inválido, redirigiendo a login");
//         // Elimina el token almacenado y redirige al login
//         await _storage.deleteAll();
//         // Aquí puedes redirigir automáticamente al login
//       } else {
//         logger.e("Error en la solicitud: ${response.statusCode}");
//       }
//     } else {
//       logger.e("No hay token almacenado");
//     }
//   }
// }
