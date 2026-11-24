import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/decaissement.dart';
import '../../theme/app_theme.dart';
import 'decaissement_filter_helpers.dart';

void showDecaissementDetailModal(
  BuildContext context,
  Decaissement d,
  NumberFormat formatter, {
  required VoidCallback onDelete,
  required VoidCallback onEdit,
}) {
  final catColor = decaissementCategoryColor(d.category);
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
                  color: catColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withAlpha(50)),
                ),
                child: Text(d.category, style: TextStyle(color: catColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              Text(dateFormat.format(d.date), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 16),
          Text(d.description, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant Décaissement :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(formatter.format(d.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.danger)),
                  ],
                ),
                if (d.notes != null && d.notes!.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notes / Remarques :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                      Text(d.notes!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ],
                if (d.reference != null && d.reference!.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Référence / Reçu :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                      Text(d.reference!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
