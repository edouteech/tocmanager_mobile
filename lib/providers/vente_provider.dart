import 'package:flutter/foundation.dart';
import '../models/vente.dart';
import '../database/database_helper.dart';

class VenteProvider extends ChangeNotifier {
  List<Vente> _items = [];
  bool _loading = false;

  List<Vente> get items => _items;
  bool get loading => _loading;

  double get totalAmount => _items.fold(0.0, (sum, v) => sum + v.total);

  Future<void> load({int? productId}) async {
    _loading = true;
    notifyListeners();
    _items = await DatabaseHelper.instance.getVentes(productId: productId);
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Vente vente) async {
    await DatabaseHelper.instance.insertVente(vente);
    await load();
  }

  Future<void> delete(Vente vente) async {
    await DatabaseHelper.instance.deleteVente(vente);
    await load();
  }
}
