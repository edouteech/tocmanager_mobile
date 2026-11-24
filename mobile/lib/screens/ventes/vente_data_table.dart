import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vente.dart';
import '../../theme/app_theme.dart';
import 'vente_filter_helpers.dart';

class VenteDataTable extends StatelessWidget {
  final List<Vente> items;
  final NumberFormat formatter;
  final ValueChanged<Vente> onTapVente;
  final ValueChanged<Vente> onEdit;
  final ValueChanged<Vente> onPrint;
  final ValueChanged<Vente> onDelete;

  const VenteDataTable({
    super.key,
    required this.items,
    required this.formatter,
    required this.onTapVente,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
  });

  String _summarizeProducts(Vente v) {
    if (v.items.isEmpty) return 'Sans article';
    final names = v.items.take(2).map((e) => e.productName).join(', ');
    return v.items.length > 2 ? '$names (+${v.items.length - 2})' : names;
  }

  double _totalQty(Vente v) => v.items.fold(0.0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            columns: const [
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Produits', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Qté total', style: TextStyle(fontWeight: FontWeight.w700)), numeric: true),
              DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w700)), numeric: true),
              DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: items.map((v) {
              final ticket = v.ticketNumber.isNotEmpty ? v.ticketNumber : 'VNT-${v.id ?? 0}';
              final client = (v.clientName != null && v.clientName!.isNotEmpty) ? v.clientName! : 'Occasionnel';
              return DataRow(
                onSelectChanged: (_) => onTapVente(v),
                cells: [
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dateFmt.format(v.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(ticket, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  )),
                  DataCell(ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(_summarizeProducts(v), overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Text(formatVenteQty(_totalQty(v)))),
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formatter.format(v.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      if (v.isCredit)
                        Text(
                          'Crédit: ${formatter.format(v.remainingAmount)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                        ),
                    ],
                  )),
                  DataCell(Text(client)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                        tooltip: 'Télécharger le ticket',
                        onPressed: () => onPrint(v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMedium),
                        tooltip: 'Modifier',
                        onPressed: () => onEdit(v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        tooltip: 'Supprimer',
                        onPressed: () => onDelete(v),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
