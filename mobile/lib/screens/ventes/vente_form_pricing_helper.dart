import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../theme/app_theme.dart';

double resolveVenteUnitPrice(
  Product product,
  List<Client> clients, {
  required double qty,
  required String clientName,
  Client? clientOverride,
}) {
  final normalized = clientName.trim().toLowerCase();
  final matchedClient = clientOverride ??
      (normalized.isEmpty
          ? null
          : clients.where((c) => c.name.trim().toLowerCase() == normalized).firstOrNull);

  if (matchedClient != null) {
    if (matchedClient.clientType == 'gros' && product.priceWholesale > 0) {
      return product.priceWholesale;
    }
    if (matchedClient.clientType == 'demi_gros' && product.priceSemiWholesale > 0) {
      return product.priceSemiWholesale;
    }
  }

  if (product.priceWholesale > 0 && product.minQtyWholesale > 0 && qty >= product.minQtyWholesale) {
    return product.priceWholesale;
  }
  if (product.priceSemiWholesale > 0 && product.minQtySemiWholesale > 0 && qty >= product.minQtySemiWholesale) {
    return product.priceSemiWholesale;
  }
  return product.price;
}

double computeVenteDiscountAmount(double raw, double subtotal, String discountType) {
  if (raw <= 0 || subtotal <= 0) return 0.0;
  if (discountType == 'percent') {
    return subtotal * (raw.clamp(0.0, 100.0) / 100.0);
  }
  return raw.clamp(0.0, subtotal);
}

double computeAvailableStockForProduct({
  required int? productId,
  required double productStock,
  required List<VenteItem> saleItems,
  required Vente? initialVente,
  int? excludeIndex,
}) {
  if (productId == null) return productStock;
  double alreadyInInitial = 0.0;
  if (initialVente != null) {
    for (final it in initialVente.items) {
      if (it.productId == productId) alreadyInInitial += it.quantity;
    }
  }
  double reservedInCart = 0.0;
  for (int i = 0; i < saleItems.length; i++) {
    if (i != excludeIndex && saleItems[i].productId == productId) {
      reservedInCart += saleItems[i].quantity;
    }
  }
  return (productStock + alreadyInInitial - reservedInCart).clamp(0.0, double.infinity);
}

List<VenteItem> buildUpdatedCartAfterAdd({
  required List<VenteItem> currentItems,
  required Product product,
  required double qty,
  required double unitPrice,
  required bool useAverageCostPrice,
}) {
  final next = currentItems.toList();
  final existingIdx = next.indexWhere((it) => it.productId == product.id);
  if (existingIdx >= 0) {
    final cur = next[existingIdx];
    final nextQty = cur.quantity + qty;
    next[existingIdx] = cur.copyWith(quantity: nextQty, unitPrice: unitPrice, total: nextQty * unitPrice);
  } else {
    next.add(VenteItem(
      productId: product.id!,
      productName: product.name,
      quantity: qty,
      unitPrice: unitPrice,
      total: qty * unitPrice,
      costPrice: product.effectiveCostPrice(useAverageCostPrice),
    ));
  }
  return next;
}

List<VenteItem> repriceCartItemsForClient({
  required List<VenteItem> currentItems,
  required List<Product> products,
  required List<Client> clients,
  required String clientName,
  Client? clientOverride,
}) {
  return currentItems.map((it) {
    final prod = products.where((p) => p.id == it.productId).firstOrNull;
    if (prod == null) return it;
    final p = resolveVenteUnitPrice(
      prod,
      clients,
      qty: it.quantity,
      clientName: clientName,
      clientOverride: clientOverride,
    );
    return it.copyWith(unitPrice: p, total: it.quantity * p);
  }).toList();
}

({List<VenteItem> items, String? error}) applyVenteCartQtyDelta({
  required List<VenteItem> currentItems,
  required int index,
  required int delta,
  required List<Product> catalogProducts,
  required Vente? initialVente,
}) {
  final next = currentItems.toList();
  final cur = next[index];
  if (delta < 0 && cur.quantity <= 1) {
    next.removeAt(index);
    return (items: next, error: null);
  }
  if (delta > 0) {
    final prod = catalogProducts.where((p) => p.id == cur.productId).firstOrNull;
    final avail = prod == null
        ? double.infinity
        : computeAvailableStockForProduct(
            productId: prod.id,
            productStock: prod.quantity,
            saleItems: currentItems,
            initialVente: initialVente,
            excludeIndex: index,
          );
    if (cur.quantity + delta > avail) {
      return (items: currentItems, error: 'Stock max atteint pour ${cur.productName}.');
    }
  }
  final q = cur.quantity + delta;
  next[index] = cur.copyWith(quantity: q, total: q * cur.unitPrice);
  return (items: next, error: null);
}

Widget buildVentePriceTierChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textMedium,
        ),
      ),
    ),
  );
}
