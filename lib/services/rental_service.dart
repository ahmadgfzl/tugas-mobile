import 'dart:convert';
import '../models/rental.dart';
import '../utils/api_endpoints.dart';
import 'api_client.dart';

class RentalService {
  Future<List<Rental>> myRentals() async {
    final res = await ApiClient.get('${ApiConfig.rentals}/me');
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List).map((e) => Rental.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed load rentals');
  }

  Future<bool> create(int motorcycleId, String startDate, String endDate) async {
    final res = await ApiClient.post(ApiConfig.rentals, {
      'motorcycle_id': motorcycleId,
      'start_date': startDate,
      'end_date': endDate
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    }
    throw Exception(data['message'] ?? 'Failed create rental');
  }
}
