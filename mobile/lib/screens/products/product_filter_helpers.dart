import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icon_helper.dart';

List<Product> filterAndSortProducts(
  List<Product> allProducts, {
  required String search,
  required int? categoryId,
  required String? statut,
  required String sortBy,
}) {
  final products = allProducts.where((p) {
    final q = search.toLowerCase();
    final matchSearch = p.name.toLowerCase().contains(q) ||
        (p.barcode?.toLowerCase().contains(q) ?? false);
    final matchCat = categoryId == null || p.categoryId == categoryId;
    final isRupture = p.quantity == 0;
    final isFaible = p.isLowStock && !isRupture;
    final matchStatut = statut == null ||
        (statut == 'lowStock' && p.isLowStock) ||
        (statut == 'rupture' && isRupture) ||
        (statut == 'faible' && isFaible) ||
        (statut == 'en_stock' && !p.isLowStock);
    return matchSearch && matchCat && matchStatut;
  }).toList();

  if (sortBy == 'price_desc') {
    products.sort((a, b) => b.price.compareTo(a.price));
  } else if (sortBy == 'stock_asc') {
    products.sort((a, b) => a.quantity.compareTo(b.quantity));
  } else if (sortBy == 'name_asc') {
    products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  return products;
}

Widget buildProductThumb(Product p, Color catColor, dynamic cat, {double size = 40}) {
  if (p.imagePath != null) {
    final file = File(p.imagePath!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 44 ? 12 : 8),
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => buildProductCategoryIcon(catColor, cat, size: size),
      ),
    );
  }
  return buildProductCategoryIcon(catColor, cat, size: size);
}

Widget buildProductCategoryIcon(Color catColor, dynamic cat, {double size = 40}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: catColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
    child: Icon(
      cat != null ? CategoryIconHelper.getIcon(cat.icon) : Icons.inventory_2_outlined,
      color: catColor,
      size: 28,
    ),
  );
}

Widget buildProductActionBtn({
  required IconData icon,
  required Color color,
  required Color bg,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 14),
    ),
  );
}

class ProductEmptyView extends StatelessWidget {
  const ProductEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun produit',
            style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Ajoutez votre premier produit', style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}
