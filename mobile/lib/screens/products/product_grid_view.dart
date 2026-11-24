import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../product_detail_screen.dart';
import 'product_filter_helpers.dart';

class ProductGridView extends StatelessWidget {
  final String search;
  final int? filterCategoryId;
  final String? filterStatut;
  final String sortBy;
  final NumberFormat formatter;
  final double maxWidth;

  const ProductGridView({
    super.key,
    required this.search,
    required this.filterCategoryId,
    required this.filterStatut,
    required this.sortBy,
    required this.formatter,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = maxWidth >= 900 ? 4 : maxWidth >= 600 ? 3 : 2;

    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, catProvider, _) {
        if (productProvider.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final products = filterAndSortProducts(
          productProvider.products,
          search: search,
          categoryId: filterCategoryId,
          statut: filterStatut,
          sortBy: sortBy,
        );

        if (products.isEmpty) return const ProductEmptyView();

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
            final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
            final catColor = cat != null ? Color(cat.color) : AppColors.primary;
            final isRupture = p.quantity == 0;
            final isFaible = p.isLowStock && !isRupture;
            final statusColor = isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
            final statusText = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';

            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Center(child: buildProductThumb(p, catColor, cat, size: 38))),
                    const SizedBox(height: 6),
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(formatter.format(p.price),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '$statusText (${p.quantity.toStringAsFixed(0)})',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
