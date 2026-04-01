import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/helpers/auth_helper.dart';
import 'package:zonix/features/utils/rif_formatter.dart';
import '../models/document.dart';

final logger = Logger();

class DocumentService {
  /// Lista los documentos del usuario autenticado (GET /api/documents/).
  Future<List<Document>> fetchMyDocuments() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/documents'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        logger.i('Documents fetched (index): ${jsonResponse.length} documents found.');
        return jsonResponse.map((doc) => Document.fromJson(doc)).toList();
      }
      logger.w('fetchMyDocuments: ${response.statusCode}');
      return [];
    } catch (e) {
      logger.e('Error during fetchMyDocuments: $e');
      throw Exception('Error fetching documents: $e');
    }
  }

  /// Lista los documentos de un usuario por su user_id (GET /api/documents/{user_id}).
  /// El backend interpreta el id como user_id para buscar el perfil.
  Future<List<Document>> fetchDocumentsByUserId(int userId) async {
    logger.i('Fetching documents for user ID: $userId');
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/documents/$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        logger.i('Documents fetched: ${jsonResponse.length} documents found.');
        return jsonResponse.map((doc) => Document.fromJson(doc)).toList();
      } else if (response.statusCode == 404) {
        logger.w('No documents found for user ID: $userId');
        return [];
      } else {
        logger.e('Unexpected error: ${response.statusCode} - ${response.body}');
        throw Exception('Error fetching documents: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error during fetchDocumentsByUserId: $e');
      throw Exception('Error fetching documents: $e');
    }
  }

  /// @deprecated Use [fetchMyDocuments] or [fetchDocumentsByUserId].
  Future<List<Document>> fetchDocuments(int id) async {
    return fetchDocumentsByUserId(id);
  }

  Future<void> createDocument(
    Document document,
    int profileId, {
    File? frontImageFile,
  }) async {
    logger.i('Creating document for profile ID: $profileId');

    try {
      final token = await AuthHelper.getToken();
      if (token == null) throw Exception('Token not found.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiUrl}/api/documents'),
      );

      // Headers: no Content-Type (multipart sets boundary); Auth + Accept
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['profile_id'] = profileId.toString();
      request.fields['type'] = document.type ?? '';
      request.fields['issued_at'] = document.issuedAt?.toIso8601String() ?? '';
      request.fields['expires_at'] = document.expiresAt?.toIso8601String() ?? '';

      // Solo CI y RIF según regla de negocio
      switch (document.type) {
        case 'ci':
          request.fields['number_ci'] = document.numberCi?.toString() ?? '';
          break;
        case 'rif':
          if (document.rifNumber != null && document.rifNumber!.trim().isNotEmpty) {
            final raw = document.rifNumber!.trim();
            request.fields['rif_number'] = formatRifDisplay(raw) ?? raw;
          }
          request.fields['taxDomicile'] = document.taxDomicile ?? '';
          break;
        default:
          logger.w('Unrecognized document type: ${document.type}');
      }

      // Attach images if available
      if (frontImageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'front_image', frontImageFile.path,
        ));
      }

      // Send the request
      final response = await request.send();

      if (response.statusCode == 201) {
        logger.i('Document created successfully.');
      } else {
        final responseBody = await response.stream.bytesToString();
        logger.e('Error creating document: ${response.statusCode} - $responseBody');
        throw Exception('Error creating document: $responseBody');
      }
    } catch (e) {
      logger.e('Exception while creating document: $e');
      rethrow;
    }
  }

  /// Actualiza un documento. Devuelve el documento actualizado si la respuesta lo incluye.
  Future<Document?> updateDocument(
    Document document,
    int profileId, {
    File? frontImageFile,
  }) async {
    logger.i('Updating document ID: ${document.id} for profile ID: $profileId');

    try {
      final token = await AuthHelper.getToken();
      if (token == null) throw Exception('Token not found.');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiUrl}/api/documents/${document.id}'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT'; // Laravel method override
      request.fields['profile_id'] = profileId.toString();
      request.fields['type'] = document.type ?? '';
      request.fields['issued_at'] = document.issuedAt?.toIso8601String() ?? '';
      request.fields['expires_at'] = document.expiresAt?.toIso8601String() ?? '';

      // Solo CI y RIF según regla de negocio
      switch (document.type) {
        case 'ci':
          request.fields['number_ci'] = document.numberCi?.toString() ?? '';
          break;
        case 'rif':
          if (document.rifNumber != null && document.rifNumber!.trim().isNotEmpty) {
            final raw = document.rifNumber!.trim();
            request.fields['rif_number'] = formatRifDisplay(raw) ?? raw;
          }
          request.fields['taxDomicile'] = document.taxDomicile ?? '';
          break;
        default:
          logger.w('Unrecognized document type: ${document.type}');
      }

      // Attach images if available
      if (frontImageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'front_image', frontImageFile.path,
        ));
      }

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        logger.i('Document updated successfully.');
        try {
          final data = json.decode(responseBody) as Map<String, dynamic>;
          final docJson = data['document'];
          if (docJson != null) {
            return Document.fromJson(Map<String, dynamic>.from(docJson as Map));
          }
        } catch (_) {}
        return null;
      } else {
        logger.e('Error updating document: ${response.statusCode} - $responseBody');
        throw Exception('Error updating document: $responseBody');
      }
    } catch (e) {
      logger.e('Exception while updating document: $e');
      rethrow;
    }
  }

  Future<void> updateStatusCheckScanner(int userId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/data-verification/$userId/update-status-check-scanner/documents'),
        headers: headers,
        // Si necesitas enviar un cuerpo, puedes descomentar lo siguiente:
        // body: json.encode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ApiException('Error al actualizar el estado: ${response.body}');
      }
    } catch (e) {
      logger.e('Error al actualizar el estado: $e');
      throw ApiException('Error al actualizar el estado: ${e.toString()}');
    }
  }
}
