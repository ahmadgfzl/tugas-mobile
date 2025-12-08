import 'package:flutter/foundation.dart';
import '../models/motorcycle.dart';
import '../services/motorcycle_service.dart';

class MotorcycleProvider extends ChangeNotifier {
  final _service = MotorcycleService();
  List<Motorcycle> items = [];
  bool loading = false;
  String? error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    
    try {
      items = await _service.list();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    
    if (!silent) {
      loading = false;
    }
    notifyListeners();
  }
}
