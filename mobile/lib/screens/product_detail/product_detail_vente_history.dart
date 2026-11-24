import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vente.dart';
import '../../providers/vente_provider.dart';
import '../../theme/app_theme.dart';

class ProductVenteHistoryTable extends StatelessWidget {
  final int? productId;
  final List<Vente> items;
  final NumberFormat formatter;
  final ValueChanged<Vente> onDelete;

  const ProductVenteHistoryTable({
    super.key,
    required this.productId,
    required this.items,
    required this.formatter,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const h = TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 52,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(label: SizedBox(width: 70, child: Center(child: Text('Qté', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 90, child: Center(child: Text('P. Unitaire', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 90, child: Center(child: Text('Total', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 110, child: Text('Client', style: h))),
        DataColumn(label: SizedBox(width: 40)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        final item = v.items.where((it) => it.productId == productId).firstOrNull ??
            (v.items.isNotEmpty ? v.items.first : null);
        final qty = item?.quantity ?? 0.0;
        final unitPrice = item?.unitPrice ?? 0.0;
        final total = item?.total ?? v.totalAmount;

        return DataRow(
          color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(Text(dateFormat.format(v.date), style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
            DataCell(Center(
              child: Text(
                qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1),
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            )),
            DataCell(Center(
                child: Text(formatter.format(unitPrice), style: const TextStyle(color: AppColors.textMedium, fontSize: 12)))),
            DataCell(Center(
              child: Text(formatter.format(total),
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
            )),
            DataCell(Text(v.clientName ?? 'Non précisé',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
            DataCell(
              InkWell(
                onTap: () => onDelete(v),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 14),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

void showConfirmDeleteProductVenteDialog(
  BuildContext context,
  Vente vente,
  VenteProvider provider,
  Future<void> Function() onDeleted,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Annuler la vente', style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('Annuler cette vente ? Le stock sera restitué.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Non')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await provider.delete(vente);
            await onDeleted();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Annuler'),
        ),
      ],
    ),
  );
}
