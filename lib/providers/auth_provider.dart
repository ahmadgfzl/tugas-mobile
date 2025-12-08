import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  UserModel? currentUser;
  bool loading = false;
  String? error;

  Future<void> login(String email, String password) async {
    loading = true; error = null; notifyListeners();
    try { currentUser = await _service.login(email, password); } catch (e){ error = e.toString(); }
    loading = false; notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    try { return await _service.register(name, email, password); } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }

  Future<void> logout() async { await _service.logout(); currentUser=null; notifyListeners(); }

  Future<void> loadProfile() async {
    try {
      final u = await _service.me();
      if (u != null) { currentUser = u; notifyListeners(); }
    } catch (e) { error = e.toString(); notifyListeners(); }
  }

  Future<bool> updateProfile({required String name, required String email, String? password}) async {
    loading = true; error = null; notifyListeners();
    try {
      final u = await _service.updateMe(name: name, email: email, password: password);
      if (u != null) currentUser = u;
      loading = false; notifyListeners();
      return true;
    } catch (e) {
      loading = false; error = e.toString(); notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword, required String confirmPassword}) async {
    loading = true; error = null; notifyListeners();
    try {
      final ok = await _service.changePassword(currentPassword: currentPassword, newPassword: newPassword, confirmPassword: confirmPassword);
      loading = false; notifyListeners();
      return ok;
    } catch (e) {
      loading = false; error = e.toString(); notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    loading = true; error = null; notifyListeners();
    try {
      final u = await _service.uploadAvatar(filePath);
      if (u != null) currentUser = u;
      loading = false; notifyListeners();
      return true;
    } catch (e) {
      loading = false; error = e.toString(); notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final ok = await _service.forgotPassword(email);
      return ok;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
