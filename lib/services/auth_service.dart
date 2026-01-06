import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user.dart';
import '../utils/api_endpoints.dart';
import 'package:http/http.dart' as http;

class AuthService {
  Future<UserModel?> login(String email, String password) async {
    final res = await ApiClient.post(ApiConfig.authLogin, {
      'email': email,
      'password': password,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['data']['token']);
      return UserModel.fromJson(data['data']['user']);
    }
    throw Exception(data['message'] ?? 'Login failed');
  }

  Future<bool> register(String name, String email, String password) async {
    final res = await ApiClient.post(ApiConfig.authRegister, {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    }
    throw Exception(data['message'] ?? 'Register failed');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<UserModel?> me() async {
    final res = await ApiClient.get(ApiConfig.usersMe);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data']);
    }
    if (res.statusCode == 401) throw Exception('Unauthorized');
    throw Exception(data['message'] ?? 'Failed load profile');
  }

  Future<UserModel?> updateMe({
    required String name,
    required String email,
    String? password,
  }) async {
    final body = {
      'name': name,
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    final res = await ApiClient.put(ApiConfig.usersMe, body);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data']);
    }
    if (res.statusCode == 401) throw Exception('Unauthorized');
    throw Exception(data['message'] ?? 'Failed update profile');
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final body = {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    };
    final res = await ApiClient.put(ApiConfig.usersPassword, body);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    }
    if (res.statusCode == 401) throw Exception('Unauthorized');
    throw Exception(data['message'] ?? 'Failed change password');
  }

  Future<UserModel?> uploadAvatar(String filePath) async {
    // We need to send multipart with Authorization header; reuse ApiClient.uploadMultipart-like logic here for simplicity
    final uri = Uri.parse(ApiConfig.usersAvatar);
    final req = http.MultipartRequest('POST', uri);
    // Attach token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final ct = res.headers['content-type'] ?? '';
    Map<String, dynamic>? data;
    if (ct.toLowerCase().startsWith('application/json')) {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      // Fall back to plain text so user sees the server error message
      final text = res.body.isNotEmpty ? res.body : 'Unknown server error';
      throw Exception('Server error (${res.statusCode}): $text');
    }
    if (res.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed upload avatar');
  }
}
