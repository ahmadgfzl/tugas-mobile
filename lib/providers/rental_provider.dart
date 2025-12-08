import 'package:flutter/foundation.dart';
import '../models/rental.dart';
import '../services/rental_service.dart';

class RentalProvider extends ChangeNotifier {
  final _service = RentalService();
  List<Rental> rentals = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading=true; error=null; notifyListeners();
    try { rentals = await _service.myRentals(); } catch (e){ error = e.toString(); }
    loading=false; notifyListeners();
  }

  Future<bool> create(int motorcycleId, String start, String end) async {
    try { final ok = await _service.create(motorcycleId, start, end); if(ok) { await load(); } return ok; } catch(e){ error=e.toString(); notifyListeners(); return false; }
  }
}
