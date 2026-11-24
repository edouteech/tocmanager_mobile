import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../product_detail_screen.dart';
import 'category_detail_table.dart';

class CategoryDetailProductsSection extends StatelessWidget {
  final List<Product> products;
  final NumberFormat formatter;
  final Color catColor;

  const CategoryDetailProductsSection({
    super.key,
    required this.products,
    required this.formatter,
    required this.catColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Produits', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              '${products.length} référence${products.length > 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: const Center(child: Text('Aucun produit dans cette catégorie', style: TextStyle(color: AppColors.textLight))),
          )
        else if (isMobile)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _mobileProductTile(context, products[index]),
          )
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: CategoryDetailProductTable(products: products, formatter: formatter),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mobileProductTile(BuildContext context, Product p) {
    final stockColor = p.isLowStock ? AppColors.danger : AppColors.success;
    final qtyStr = p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: catColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.inventory_2_outlined, color: catColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(p.price),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: stockColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Text('$qtyStr ${p.unit}', style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
