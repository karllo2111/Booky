import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path, {bool auth = true, Map<String, String>? query}) async {
    try {
      var uri = Uri.parse('${AppConstants.baseUrl}$path');
      if (query != null && query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }
      final response = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(AppConstants.connectTimeout);
      return _handle(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectTimeout);
      return _handle(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectTimeout);
      return _handle(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.connectTimeout);
      return _handle(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('${AppConstants.baseUrl}$path'), headers: await _headers())
          .timeout(AppConstants.connectTimeout);
      return _handle(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }

  static Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final msg = body['message'] ?? body['error'] ?? 'Terjadi kesalahan';
    throw Exception(msg);
  }

  /// Multipart POST for file uploads (e.g. book cover image)
  static Future<Map<String, dynamic>> multipartPost(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileField = 'cover_image',
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final request = http.MultipartRequest('POST', uri);

      final token = await _getToken();
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll(fields);
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      final streamedResponse = await request.send().timeout(AppConstants.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handle(response);
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }
}

