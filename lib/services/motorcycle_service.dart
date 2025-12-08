import 'dart:convert';
import '../models/motorcycle.dart';
import '../utils/api_endpoints.dart';
import 'api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class MotorcycleService {
  Future<List<Motorcycle>> list() async {
    final res = await ApiClient.get(ApiConfig.motorcycles);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => Motorcycle.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed load motorcycles');
  }

  Future<Motorcycle> uploadImage(int id, File file) async {
    final streamed = await ApiClient.uploadMultipart(ApiConfig.motorcycleImage(id), fieldName: 'image', filePath: file.path);
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return Motorcycle.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed upload image');
  }

  Future<bool> deleteImage(int motorcycleId, int imageId) async {
    final res = await ApiClient.delete(ApiConfig.motorcycleDeleteImage(motorcycleId, imageId));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) return true;
    throw Exception(data['message'] ?? 'Failed delete image');
  }

  Future<List<MotorcycleImage>> uploadImagesPaths(int id, List<String> paths) async {
    if (paths.isEmpty) return [];
    final streamed = await ApiClient.uploadMultipartMany(ApiConfig.motorcycleImages(id), fieldName: 'images', filePaths: paths);
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final list = (data['data']['images'] as List?) ?? [];
      return list.map((it) {
        final id = (it['id'] is int) ? it['id'] as int : 0;
        final url = (it['image_url'] as String?);
        return MotorcycleImage(id: id, url: url ?? '');
      }).toList();
    }
    throw Exception(data['message'] ?? 'Failed upload images');
  }
}
