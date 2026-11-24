import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../product_detail_screen.dart';

class HomeStockByCategoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> stockByCategory;
  final NumberFormat formatter;

  const HomeStockByCategoryCard({
    super.key,
    required this.stockByCategory,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = stockByCategory
        .map((e) => (e['value'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock par catégorie',
          style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: stockByCategory.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final value = (cat['value'] as num).toDouble();
              final color = Color(cat['color'] as int);
              final ratio = maxValue > 0 ? value / maxValue : 0.0;
              final count = cat['count'] as int;

              return Column(
                children: [
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text('$count produit${count > 1 ? 's' : ''}',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(
                        formatter.format(value),
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 7,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class HomeRecentProductsCard extends StatelessWidget {
  final NumberFormat formatter;
  final void Function(int, {String? statusFilter})? onNav;
  final VoidCallback onReloadData;

  const HomeRecentProductsCard({
    super.key,
    required this.formatter,
    this.onNav,
    required this.onReloadData,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.products.take(5).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Produits récents',
                    style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => onNav?.call(1),
                  child: const Text('Voir tout', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: products.asMap().entries.map((entry) {
                  final i = entry.key;
                  final product = entry.value;
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, color: AppColors.divider, indent: 60),
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                            ).then((_) => onReloadData());
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: product.isLowStock ? AppColors.dangerLight : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: product.isLowStock ? AppColors.danger : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Stock : ${product.quantity} ${product.unit}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                          ),
                          trailing: Text(
                            formatter.format(product.price),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
