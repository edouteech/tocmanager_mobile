import 'package:flutter/foundation.dart';
import '../models/approvisionnement.dart';
import '../database/database_helper.dart';

class ApprovisionnementProvider extends ChangeNotifier {
  List<Approvisionnement> _items = [];
  bool _loading = false;

  List<Approvisionnement> get items => _items;
  bool get loading => _loading;

  double get totalAmount =>
      _items.fold(0.0, (sum, a) => sum + a.total);

  Future<void> load({int? productId}) async {
    _loading = true;
    notifyListeners();
    _items = await DatabaseHelper.instance.getApprovisionnements(productId: productId);
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Approvisionnement appro) async {
    await DatabaseHelper.instance.insertApprovisionnement(appro);
    await load();
  }

  Future<void> delete(Approvisionnement appro) async {
    await DatabaseHelper.instance.deleteApprovisionnement(appro);
    await load();
  }
}
