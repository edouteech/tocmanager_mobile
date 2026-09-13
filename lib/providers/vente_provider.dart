import 'package:flutter/foundation.dart';
import '../models/vente.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

class VenteProvider extends ChangeNotifier {
  List<Vente> _items = [];
  bool _loading = false;
  int? _activeProductId;

  // Cart state for active sale session
  final List<VenteItem> _cartItems = [];

  List<Vente> get items => _items;
  bool get loading => _loading;

  List<VenteItem> get cartItems => List.unmodifiable(_cartItems);
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + item.total);
  int get cartCount => _cartItems.length;

  double get totalAmount => _items.fold(0.0, (sum, v) => sum + v.totalAmount);
  double get totalSalesAmount => totalAmount;

  double get todaySalesAmount {
    final now = DateTime.now();
    return _items.where((v) {
      return v.date.year == now.year && v.date.month == now.month && v.date.day == now.day;
    }).fold(0.0, (sum, v) => sum + v.totalAmount);
  }

  Future<void> load({int? productId}) async {
    _activeProductId = productId;
    _loading = true;
    notifyListeners();
    _items = await DatabaseHelper.instance.getVentes(productId: productId);
    _loading = false;
    notifyListeners();
  }

  void addToCart(
    Product product, {
    double quantity = 1.0,
    double? customUnitPrice,
    bool featureEnabled = false,
  }) {
    final unitPrice = customUnitPrice ?? product.price;
    final existingIdx = _cartItems.indexWhere((it) => it.productId == product.id);

    if (existingIdx >= 0) {
      final existing = _cartItems[existingIdx];
      final newQty = existing.quantity + quantity;
      _cartItems[existingIdx] = existing.copyWith(
        quantity: newQty,
        unitPrice: unitPrice,
        total: newQty * unitPrice,
      );
    } else {
      _cartItems.add(VenteItem(
        productId: product.id!,
        productName: product.name,
        quantity: quantity,
        unitPrice: unitPrice,
        total: quantity * unitPrice,
        costPrice: product.effectiveCostPrice(featureEnabled),
      ));
    }
    notifyListeners();
  }

  void updateCartQty(int index, double quantity) {
    if (index >= 0 && index < _cartItems.length) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        final existing = _cartItems[index];
        _cartItems[index] = existing.copyWith(
          quantity: quantity,
          total: quantity * existing.unitPrice,
        );
      }
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> add(Vente vente) async {
    await DatabaseHelper.instance.insertVente(vente);
    clearCart();
    await load(productId: _activeProductId);
  }

  Future<void> delete(Vente vente) async {
    await DatabaseHelper.instance.deleteVente(vente);
    await load(productId: _activeProductId);
  }
}
