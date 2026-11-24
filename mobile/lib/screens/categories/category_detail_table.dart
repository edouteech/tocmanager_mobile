import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../product_detail_screen.dart';

class CategoryDetailProductTable extends StatelessWidget {
  final List<Product> products;
  final NumberFormat formatter;

  const CategoryDetailProductTable({
    super.key,
    required this.products,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    const h = TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);

    return DataTable(
      showCheckboxColumn: false,
      headingRowHeight: 40,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 56,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: SizedBox(width: 130, child: Text('Produit', style: h))),
        DataColumn(label: SizedBox(width: 90, child: Center(child: Text('P. Vente', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 90, child: Center(child: Text('Stock', style: h)))),
        DataColumn(label: SizedBox(width: 100, child: Center(child: Text('Valeur stock', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 70, child: Center(child: Text('Statut', style: h)))),
      ],
      rows: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final stockColor = p.isLowStock ? AppColors.danger : AppColors.success;
        final qtyStr = p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1);

        return DataRow(
          onSelectChanged: (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
          color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.description != null)
                    SizedBox(
                      width: 130,
                      child: Text(
                        p.description!,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(Center(child: Text(formatter.format(p.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)))),
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: stockColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                  child: Text('$qtyStr ${p.unit}', style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
            ),
            DataCell(Center(child: Text(formatter.format(p.stockValue), style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 12)))),
            DataCell(
              Center(
                child: p.isLowStock
                    ? const Icon(Icons.warning_amber, color: AppColors.danger, size: 18)
                    : const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
