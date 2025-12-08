import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_endpoints.dart';
import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  Future<String> fetchBankAccountInfo() async {
    final res = await ApiClient.get(ApiConfig.settingsPayment);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final d = data['data'];
      return '${d['bank_name']} ${d['account_number']} a.n ${d['account_name']}';
    }
    throw Exception(data['message'] ?? 'Failed load payment settings');
  }

  Future<Map<String, String>> fetchBankAccountSettings() async {
    final res = await ApiClient.get(ApiConfig.settingsPayment);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final d = data['data'] as Map<String, dynamic>;
      return {
        'bank_name': d['bank_name'] ?? '',
        'account_number': d['account_number'] ?? '',
        'account_name': d['account_name'] ?? '',
        'whatsapp_phone': d['whatsapp_phone'] ?? '',
      };
    }
    throw Exception(data['message'] ?? 'Failed load payment settings');
  }

  Future<List<Map<String, dynamic>>> listMyPayments() async {
    final res = await ApiClient.get(ApiConfig.paymentsMy);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final List items = data['data'] ?? [];
      return items.cast<Map<String, dynamic>>();
    }
    throw Exception(data['message'] ?? 'Failed load my payments');
  }
  Future<Payment> createPayment({required int rentalId, required double amount, required String bankAccount}) async {
    final res = await ApiClient.post(ApiConfig.payments, {
      'rental_id': rentalId,
      'amount': amount,
      'bank_account': bankAccount,
    });
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return Payment.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed create payment');
  }

  Future<Payment> uploadProof({required int paymentId, required String filePath}) async {
    final streamed = await ApiClient.uploadMultipart(ApiConfig.paymentProof(paymentId), fieldName: 'proof', filePath: filePath);
    final res = await http.Response.fromStream(streamed);
    final ct = res.headers['content-type'] ?? '';
    if (!ct.toLowerCase().startsWith('application/json')) {
      throw Exception('Server returned non-JSON response: ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return Payment.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed upload proof');
  }

  Future<List<Payment>> listPayments() async {
    final res = await ApiClient.get(ApiConfig.payments);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final List items = data['data'] ?? [];
      return items.map((e) => Payment.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed load payments');
  }
}
