import 'package:flutter/foundation.dart' hide Category;
import '../database/database_helper.dart';
import '../models/category.dart';
import '../services/sync_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _loading = false;

  List<Category> get categories => _categories;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _categories = await DatabaseHelper.instance.getCategories();
    _loading = false;
    notifyListeners();
  }

  Future<int> add(Category category) async {
    final id = await DatabaseHelper.instance.insertCategory(category);
    await load();
    SyncService.instance.notifyLocalMutation();
    return id;
  }

  Future<void> update(Category category) async {
    await DatabaseHelper.instance.updateCategory(category);
    await load();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await load();
    SyncService.instance.notifyLocalMutation();
  }
}
