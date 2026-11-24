import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../product_detail_screen.dart';
import 'product_filter_helpers.dart';

class ProductListView extends StatelessWidget {
  final String search;
  final int? filterCategoryId;
  final String? filterStatut;
  final String sortBy;
  final NumberFormat formatter;
  final ValueChanged<Product> onAdjustStock;
  final ValueChanged<Product> onEditProduct;

  const ProductListView({
    super.key,
    required this.search,
    required this.filterCategoryId,
    required this.filterStatut,
    required this.sortBy,
    required this.formatter,
    required this.onAdjustStock,
    required this.onEditProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, catProvider, _) {
        if (productProvider.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final featureEnabled = context.watch<SettingsProvider>().settings.enableAverageCostPrice;
        final products = filterAndSortProducts(
          productProvider.products,
          search: search,
          categoryId: filterCategoryId,
          statut: filterStatut,
          sortBy: sortBy,
        );

        if (products.isEmpty) return const ProductEmptyView();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
            final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
            final catColor = cat != null ? Color(cat.color) : AppColors.primary;
            final isRupture = p.quantity == 0;
            final isFaible = p.isLowStock && !isRupture;
            final statusColor = isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
            final statusText = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  leading: buildProductThumb(p, catColor, cat, size: 38),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(formatter.format(p.price),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (cat != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: catColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  cat.name,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          if (cat != null) const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '$statusText (${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit})',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (p.quantity > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Valeur : ${formatter.format(p.stockSaleValue)} • Coût : ${formatter.format(p.stockCostWithFeature(featureEnabled))}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildProductActionBtn(
                        icon: Icons.edit_note,
                        color: AppColors.purple,
                        bg: AppColors.purple.withAlpha(20),
                        onTap: () => onAdjustStock(p),
                      ),
                      const SizedBox(width: 4),
                      buildProductActionBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.textMedium,
                        bg: AppColors.background,
                        onTap: () => onEditProduct(p),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
