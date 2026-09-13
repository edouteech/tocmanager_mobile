import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _loading = false;

  List<Supplier> get suppliers => _suppliers;
  bool get loading => _loading;

  double get totalDettes => _suppliers.fold(0, (sum, s) => sum + (s.balance > 0 ? s.balance : 0));

  Future<void> loadSuppliers() async {
    _loading = true;
    notifyListeners();
    _suppliers = await DatabaseHelper.instance.getSuppliers();
    _loading = false;
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    final id = await DatabaseHelper.instance.insertSupplier(supplier);
    _suppliers.insert(0, supplier.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await DatabaseHelper.instance.updateSupplier(supplier);
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _suppliers[idx] = supplier;
      notifyListeners();
    }
  }

  Future<void> deleteSupplier(int id) async {
    await DatabaseHelper.instance.deleteSupplier(id);
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> recordSupplierPayment(int supplierId, double amount) async {
    await DatabaseHelper.instance.recordSupplierPayment(supplierId, amount);
    await loadSuppliers();
  }
}
