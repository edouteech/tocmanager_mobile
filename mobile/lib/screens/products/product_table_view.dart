import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../product_detail_screen.dart';
import 'product_bulk_and_delete.dart';
import 'product_filter_helpers.dart';

class ProductTableView extends StatelessWidget {
  final String search;
  final int? filterCategoryId;
  final String? filterStatut;
  final String sortBy;
  final NumberFormat formatter;
  final ValueChanged<Product> onAdjustStock;
  final ValueChanged<Product> onEditProduct;

  const ProductTableView({
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

        final products = filterAndSortProducts(
          productProvider.products,
          search: search,
          categoryId: filterCategoryId,
          statut: filterStatut,
          sortBy: sortBy,
        );

        if (products.isEmpty) return const ProductEmptyView();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  columnSpacing: 14,
                  horizontalMargin: 12,
                  headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
                  dividerThickness: 1,
                  columns: const [
                    DataColumn(label: SizedBox(width: 40)),
                    DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                    DataColumn(label: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                    DataColumn(label: Text('Prix vente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)), numeric: true),
                    DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)), numeric: true),
                    DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                    DataColumn(label: SizedBox(width: 80)),
                  ],
                  rows: products.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
                    final catColor = cat != null ? Color(cat.color) : AppColors.primary;
                    final isRupture = p.quantity == 0;
                    final isFaible = p.isLowStock && !isRupture;
                    final statusColor = isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
                    final statusLabel = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';

                    return DataRow(
                      color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
                      cells: [
                        DataCell(buildProductThumb(p, catColor, cat, size: 32)),
                        DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark))),
                        DataCell(Text(cat?.name ?? '—', style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
                        DataCell(Text(formatter.format(p.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                        DataCell(Text('${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                        DataCell(Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                            child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                          ),
                        )),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildProductActionBtn(
                                icon: Icons.edit_note,
                                color: AppColors.purple,
                                bg: AppColors.purple.withAlpha(20),
                                onTap: () => onAdjustStock(p),
                              ),
                              const SizedBox(width: 6),
                              buildProductActionBtn(
                                icon: Icons.visibility_outlined,
                                color: AppColors.success,
                                bg: AppColors.successLight,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                              ),
                              const SizedBox(width: 6),
                              buildProductActionBtn(
                                icon: Icons.edit_outlined,
                                color: AppColors.primary,
                                bg: AppColors.primaryLight,
                                onTap: () => onEditProduct(p),
                              ),
                              const SizedBox(width: 6),
                              buildProductActionBtn(
                                icon: Icons.delete_outline,
                                color: AppColors.danger,
                                bg: AppColors.dangerLight,
                                onTap: () => showConfirmDeleteProductModal(context, p, productProvider),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
