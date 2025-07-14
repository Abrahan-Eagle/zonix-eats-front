import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/utils/constants.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';





final logger = Logger();
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

class ProfileService {
  final _storage = const FlutterSecureStorage();

  // Obtiene el token almacenado.
  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  // Recupera un perfil por ID.
  Future<Profile?> getProfileById(int id) async {
        logger.i('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: $id');
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/profiles/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
      
    if (response.statusCode == 200) {
    
      final data = jsonDecode(response.body);
      return Profile.fromJson(data);
    } else {
      throw Exception('Error al obtener el perfil');
    }
  }

  // Recupera todos los perfiles.
  Future<List<Profile>> getAllProfiles() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/profiles'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Profile.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener los perfiles');
    }
  }
// Crea un nuevo perfil.
Future<void> createProfile(Profile profile, int userId, {File? imageFile}) async {
  try {
    final token = await _getToken();
    if (token == null) throw Exception('Token no encontrado.');

    final uri = Uri.parse('$baseUrl/api/profiles');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['firstName'] = profile.firstName
      ..fields['middleName'] = profile.middleName ?? '' 
      ..fields['lastName'] = profile.lastName
      ..fields['secondLastName'] = profile.secondLastName ?? ''
      ..fields['date_of_birth'] = profile.dateOfBirth
      ..fields['maritalStatus'] = profile.maritalStatus
      ..fields['sex'] = profile.sex
      ..fields['user_id'] = userId.toString(); // Agregar user_id

    // Agrega la imagen si está presente.
    if (imageFile != null) {
      final image = await http.MultipartFile.fromPath(
        'photo_users',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), // Ajusta si necesitas otro formato.
      );
      request.files.add(image);
    }

    final response = await request.send();

    // Loguea el response recibido.
    logger.i('Response Status: ${response.statusCode}');
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      logger.i('Perfil creado exitosamente: ${responseData.body}');
    } else {
      logger.e('Error al crear el perfil: ${responseData.body}');
      throw Exception('Error al crear el perfil: ${responseData.body}');
    }
  } catch (e) {
    logger.e('Excepción: $e');
    rethrow;
  }
}


    // Actualiza un perfil existente.
  Future<void> updateProfile(int id, Profile profile, {File? imageFile}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token no encontrado.');

      final uri = Uri.parse('$baseUrl/api/profiles/$id');
      final request = http.MultipartRequest('POST', uri) // Cambiar PUT a POST si tu API requiere POST.
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['firstName'] = profile.firstName
        ..fields['middleName'] = profile.middleName ?? '' 
        ..fields['lastName'] = profile.lastName
        ..fields['secondLastName'] = profile.secondLastName ?? ''
        ..fields['date_of_birth'] = profile.dateOfBirth
        ..fields['maritalStatus'] = profile.maritalStatus
        ..fields['sex'] = profile.sex;

      // Agrega la imagen si está presente.
      if (imageFile != null) {
        final image = await http.MultipartFile.fromPath(
          'photo_users',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), // Ajusta si necesitas otro formato.
        );
        request.files.add(image);
      }

      final response = await request.send();

      // Loguea el response recibido.
      logger.i('Response Status: ${response.statusCode}');
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        logger.i('Perfil actualizado exitosamente: ${responseData.body}');
      } else {
        logger.e('Error al actualizar el perfil: ${responseData.body}');
        throw Exception('Error al actualizar el perfil: ${responseData.body}');
      }
    } catch (e) {
      logger.e('Excepción: $e');
      rethrow;
    }
  }






Future<void> updateStatusCheckScanner(int userId, int selectedOptionId) async {
  String? token = await _getToken();
  if (token == null) {
    logger.e('Token no encontrado');
    throw ApiException('Token no encontrado. Por favor, inicia sesión.'); // Aquí lanzamos ApiException
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/data-verification/$userId/update-status-check-scanner/profiles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'selectedOptionId': selectedOptionId,
      }), // Aquí se envía el selectedOptionId
    ).timeout(const Duration(seconds: 10));


    if (response.statusCode != 200) {
      throw ApiException('Error al actualizar el estado: ${response.body}');
    }
  } catch (e) {
    logger.e('Error al actualizar el estado: $e');
    throw ApiException('Error al actualizar el estado: ${e.toString()}');
  }
}

  // Obtener historial de actividad del usuario
  Future<Map<String, dynamic>> getActivityHistory() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/buyer/activity'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el historial de actividad');
    }
  }

  // Exportar todos los datos personales del usuario
  Future<Map<String, dynamic>> exportPersonalData() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/buyer/export'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al exportar los datos personales');
    }
  }

  // Obtener configuración de privacidad
  Future<Map<String, dynamic>> getPrivacySettings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/buyer/privacy'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener la configuración de privacidad');
    }
  }

  // Actualizar configuración de privacidad
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/buyer/privacy'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(settings),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la configuración de privacidad');
    }
  }

  // Eliminar cuenta del usuario
  Future<void> deleteAccount() async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/buyer/account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la cuenta');
    }
  }

}
