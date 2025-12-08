import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<http.Response> get(String path) async {
    final headers = await _headers();
    return http.get(Uri.parse(path), headers: headers);
  }

  static Future<http.Response> post(String path, Map body) async {
    final headers = await _headers();
    return http.post(Uri.parse(path), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String path, Map body) async {
    final headers = await _headers();
    return http.put(Uri.parse(path), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> patch(String path, Map body) async {
    final headers = await _headers();
    return http.patch(Uri.parse(path), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    final headers = await _headers();
    return http.delete(Uri.parse(path), headers: headers);
  }

  static Future<http.StreamedResponse> uploadMultipart(String path, {required String fieldName, required String filePath}) async {
    final token = await _token();
    final uri = Uri.parse(path);
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final file = await http.MultipartFile.fromPath(fieldName, filePath);
    request.files.add(file);
    return request.send();
  }

  static Future<http.StreamedResponse> uploadMultipartMany(String path, {required String fieldName, required List<String> filePaths}) async {
    final token = await _token();
    final uri = Uri.parse(path);
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    for (final p in filePaths) {
      final file = await http.MultipartFile.fromPath(fieldName, p);
      request.files.add(file);
    }
    return request.send();
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
  }
}
