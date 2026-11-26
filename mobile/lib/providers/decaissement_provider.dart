import 'package:flutter/foundation.dart';
import '../models/decaissement.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';

class DecaissementProvider extends ChangeNotifier {
  List<Decaissement> _items = [];
  bool _loading = false;

  List<Decaissement> get items => _items;
  bool get loading => _loading;

  double get totalAmount =>
      _items.fold(0.0, (sum, d) => sum + d.amount);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await DatabaseHelper.instance.getDecaissements();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Decaissement dec) async {
    await DatabaseHelper.instance.insertDecaissement(dec);
    await load();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> update(Decaissement dec) async {
    await DatabaseHelper.instance.updateDecaissement(dec);
    await load();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteDecaissement(id);
    await load();
    SyncService.instance.notifyLocalMutation();
  }
}
