import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/approvisionnement.dart';
import '../../theme/app_theme.dart';

void showApprovisionDetailModal(
  BuildContext context,
  Approvisionnement a,
  String prodName,
  NumberFormat formatter, {
  required VoidCallback onDelete,
  required VoidCallback onEdit,
}) {
  final dateFormat = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: a.isCredit ? AppColors.danger.withAlpha(20) : AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.isCredit ? 'À Crédit' : 'Réglé Cash',
                  style: TextStyle(
                    color: a.isCredit ? AppColors.danger : AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(dateFormat.format(a.date), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 16),
          Text(prodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _row('Quantité :', '${a.quantity}', valueWeight: FontWeight.w700, valueSize: 13),
                const Divider(height: 12),
                _row('Prix d\'achat unitaire :', formatter.format(a.unitPrice), valueWeight: FontWeight.w700, valueSize: 13),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Achats :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(formatter.format(a.total),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                  ],
                ),
                if (a.supplier != null && a.supplier!.isNotEmpty) ...[
                  const Divider(height: 12),
                  _row('Fournisseur :', a.supplier!, valueWeight: FontWeight.w700, valueSize: 13),
                ],
                if (a.isCredit) ...[
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Montant Réglé :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                      Text(formatter.format(a.paidAmount),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reste Dû :',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger)),
                      Text(formatter.format(a.remainingAmount),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.danger)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Supprimer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _row(String label, String value, {required FontWeight valueWeight, required double valueSize}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
      Text(value, style: TextStyle(fontWeight: valueWeight, fontSize: valueSize)),
    ],
  );
}
