import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/approvisionnement.dart';
import '../../models/product.dart';
import '../../providers/approvisionnement_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';

class ApprovisionDataTable extends StatelessWidget {
  final List<Approvisionnement> items;
  final List<Product> products;
  final NumberFormat formatter;
  final ValueChanged<Approvisionnement> onEdit;
  final ValueChanged<Approvisionnement> onDelete;

  const ApprovisionDataTable({
    super.key,
    required this.items,
    required this.products,
    required this.formatter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const h = TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 58,
      dataRowMaxHeight: 58,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(label: SizedBox(width: 130, child: Text('Produit', style: h))),
        DataColumn(label: SizedBox(width: 70, child: Center(child: Text('Qté', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 90, child: Center(child: Text('P. Unitaire', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 100, child: Center(child: Text('Total', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 110, child: Text('Fournisseur', style: h))),
        DataColumn(label: SizedBox(width: 70)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        final product = products.where((p) => p.id == a.productId).firstOrNull;

        return DataRow(
          color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(Text(dateFormat.format(a.date), style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
            DataCell(Text(
              product?.name ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(Center(
              child: Text(
                a.quantity.toStringAsFixed(a.quantity.truncateToDouble() == a.quantity ? 0 : 1),
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            )),
            DataCell(Center(
              child: Text(formatter.format(a.unitPrice), style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(a.total),
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            )),
            DataCell(Text(
              a.supplier ?? '—',
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tableBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                    onTap: () => onEdit(a),
                  ),
                  const SizedBox(width: 6),
                  _tableBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                    onTap: () => onDelete(a),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _tableBtn({
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
}

void showDeleteApprovisionDialog(
  BuildContext context,
  Approvisionnement appro,
  ApprovisionnementProvider approProvider,
  ProductProvider productProvider,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('Supprimer cet approvisionnement ? Le stock sera mis à jour.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            final supplierProvider = context.read<SupplierProvider>();
            Navigator.pop(ctx);
            await approProvider.delete(appro);
            if (context.mounted) {
              await productProvider.load();
              await supplierProvider.loadSuppliers();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
