import 'package:flutter/foundation.dart' hide Category;
import '../database/database_helper.dart';
import '../models/category.dart';

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

  Future<void> add(Category category) async {
    await DatabaseHelper.instance.insertCategory(category);
    await load();
  }

  Future<void> update(Category category) async {
    await DatabaseHelper.instance.updateCategory(category);
    await load();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await load();
  }
}
