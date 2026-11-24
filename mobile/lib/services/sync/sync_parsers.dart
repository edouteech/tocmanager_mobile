import 'package:flutter/material.dart';
import '../../utils/category_icon_helper.dart';

class SyncParsers {
  static const Map<String, String> entityTableMap = {
    'category': 'categories',
    'product': 'products',
    'supplier': 'suppliers',
    'client': 'clients',
    'vente': 'ventes',
    'decaissement': 'decaissements',
    'approvisionnement': 'approvisionnements',
    'audit_log': 'audit_logs',
  };

  static int parseCategoryColor(dynamic raw) {
    if (raw is int) return raw;
    final str = raw?.toString().trim() ?? '';
    if (str.isEmpty) return 0xFF2196F3;
    if (str.startsWith('#')) {
      final hex = str.substring(1);
      if (hex.length == 6) return int.tryParse('FF$hex', radix: 16) ?? 0xFF2196F3;
      if (hex.length == 8) return int.tryParse(hex, radix: 16) ?? 0xFF2196F3;
    }
    return int.tryParse(str) ?? 0xFF2196F3;
  }

  static int parseCategoryIcon(dynamic raw) {
    if (raw is int) return CategoryIconHelper.getIcon(raw).codePoint;
    final str = raw?.toString().trim() ?? '';
    if (str.isEmpty) return Icons.category.codePoint;
    final numeric = int.tryParse(str);
    if (numeric != null) return CategoryIconHelper.getIcon(numeric).codePoint;
    switch (str.toLowerCase()) {
      case 'package':
      case 'inventory_2':
        return Icons.inventory_2.codePoint;
      case 'shopping_bag':
      case 'shoppingbag':
        return Icons.shopping_bag.codePoint;
      case 'restaurant':
      case 'fastfood':
        return Icons.restaurant.codePoint;
      case 'checkroom':
        return Icons.checkroom.codePoint;
      case 'devices':
      case 'computer':
        return Icons.devices.codePoint;
      default:
        return Icons.category.codePoint;
    }
  }
}
