import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _loading = false;

  List<Product> get products => _products;
  bool get loading => _loading;
  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock).toList();

  Future<void> load({int? categoryId}) async {
    _loading = true;
    notifyListeners();
    _products = await DatabaseHelper.instance.getProducts(categoryId: categoryId);
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    await load();
  }

  Future<void> update(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await load();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await load();
  }
}
