import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/decaissement.dart';
import '../../providers/decaissement_provider.dart';
import '../../theme/app_theme.dart';
import 'decaissement_filter_helpers.dart';

class DecaissementDataTable extends StatelessWidget {
  final List<Decaissement> items;
  final NumberFormat formatter;
  final ValueChanged<Decaissement> onEdit;
  final ValueChanged<Decaissement> onDelete;

  const DecaissementDataTable({
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
      headingRowHeight: 44,
      dataRowMinHeight: 58,
      dataRowMaxHeight: 58,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(label: SizedBox(width: 160, child: Text('Description', style: h))),
        DataColumn(label: SizedBox(width: 100, child: Text('Catégorie', style: h))),
        DataColumn(label: SizedBox(width: 100, child: Center(child: Text('Montant', style: h))), numeric: true),
        DataColumn(label: SizedBox(width: 100, child: Text('Référence', style: h))),
        DataColumn(label: SizedBox(width: 76, child: Center(child: Text('Actions', style: h)))),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final d = entry.value;
        final catColor = decaissementCategoryColor(d.category);

        return DataRow(
          color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(Text(dateFormat.format(d.date), style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
            DataCell(
              SizedBox(
                width: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.description,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.notes != null)
                      Text(
                        d.notes!,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: catColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                child: Text(d.category, style: TextStyle(color: catColor, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ),
            DataCell(Center(
              child: Text(
                formatter.format(d.amount),
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            )),
            DataCell(Text(
              d.reference ?? '—',
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                    onTap: () => onEdit(d),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                    onTap: () => onDelete(d),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}

void showDeleteDecaissementDialog(BuildContext context, Decaissement dec, DecaissementProvider provider) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Supprimer "${dec.description}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            await provider.delete(dec.id!);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
