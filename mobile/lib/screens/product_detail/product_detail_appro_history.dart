import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/approvisionnement.dart';
import '../../providers/approvisionnement_provider.dart';
import '../../theme/app_theme.dart';

class ProductHistorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool loading;
  final String empty;
  final Widget? child;

  const ProductHistorySection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.loading,
    required this.empty,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (child == null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Text(empty, style: const TextStyle(color: AppColors.textLight))),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
            ),
          ),
      ],
    );
  }
}

class ProductApproHistoryTable extends StatelessWidget {
  final List<Approvisionnement> items;
  final NumberFormat formatter;
  final ValueChanged<Approvisionnement> onEdit;
  final ValueChanged<Approvisionnement> onDelete;

  const ProductApproHistoryTable({
    super.key,
    required this.items,
    required this.formatter,
    required this.onEdit,
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
        DataColumn(label: SizedBox(width: 110, child: Text('Fournisseur', style: h))),
        DataColumn(label: SizedBox(width: 70)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return DataRow(
          color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(Text(dateFormat.format(a.date), style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
            DataCell(Center(
              child: Text(
                a.quantity.toStringAsFixed(a.quantity.truncateToDouble() == a.quantity ? 0 : 1),
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            )),
            DataCell(Center(
                child: Text(formatter.format(a.unitPrice), style: const TextStyle(color: AppColors.textMedium, fontSize: 12)))),
            DataCell(Center(
              child: Text(formatter.format(a.total),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            )),
            DataCell(Text(a.supplier ?? '—',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(Icons.edit_outlined, AppColors.primary, AppColors.primaryLight, () => onEdit(a)),
                  const SizedBox(width: 6),
                  _iconBtn(Icons.delete_outline, AppColors.danger, AppColors.dangerLight, () => onDelete(a)),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _iconBtn(IconData icon, Color color, Color bg, VoidCallback onTap) {
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

void showConfirmDeleteProductApproDialog(
  BuildContext context,
  Approvisionnement appro,
  ApprovisionnementProvider provider,
  Future<void> Function() onDeleted,
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
            Navigator.pop(ctx);
            await provider.delete(appro);
            await onDeleted();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
