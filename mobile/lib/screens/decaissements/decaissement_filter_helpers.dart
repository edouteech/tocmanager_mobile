import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/decaissement.dart';
import '../../theme/app_theme.dart';

const List<String> kDecaissementCategories = [
  'Fournisseur',
  'Loyer',
  'Salaires',
  'Transport',
  'Divers',
];

Color decaissementCategoryColor(String category) {
  switch (category) {
    case 'Fournisseur':
      return AppColors.primary;
    case 'Loyer':
      return AppColors.purple;
    case 'Salaires':
      return AppColors.success;
    case 'Transport':
      return const Color(0xFFF39C12);
    default:
      return AppColors.textMedium;
  }
}

String decaissementPeriodLabel(String filterPeriod) {
  if (filterPeriod == 'today') return 'Aujourd\'hui';
  if (filterPeriod == 'yesterday') return 'Hier';
  if (filterPeriod == 'month') return 'Ce mois-ci';
  return 'Toutes les périodes';
}

List<Decaissement> filterAndSortDecaissements(
  List<Decaissement> allItems, {
  String? filterCategory,
  required String filterPeriod,
  required String search,
  required String sortBy,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final filtered = allItems.where((d) {
    if (filterCategory != null && d.category != filterCategory) return false;
    final dDate = DateTime(d.date.year, d.date.month, d.date.day);
    if (filterPeriod == 'today' && !dDate.isAtSameMomentAs(today)) return false;
    if (filterPeriod == 'yesterday' && !dDate.isAtSameMomentAs(yesterday)) return false;
    if (filterPeriod == 'month' && (d.date.year != now.year || d.date.month != now.month)) return false;

    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      final matchReason = d.description.toLowerCase().contains(q);
      final matchCat = d.category.toLowerCase().contains(q);
      final matchNotes = (d.notes ?? '').toLowerCase().contains(q);
      final matchRef = (d.reference ?? '').toLowerCase().contains(q);
      if (!matchReason && !matchCat && !matchNotes && !matchRef) return false;
    }
    return true;
  }).toList();

  if (sortBy == 'amount_desc') {
    filtered.sort((a, b) => b.amount.compareTo(a.amount));
  } else if (sortBy == 'category_asc') {
    filtered.sort((a, b) => a.category.compareTo(b.category));
  } else if (sortBy == 'recent') {
    filtered.sort((a, b) => b.date.compareTo(a.date));
  }

  return filtered;
}

class DecaissementSummaryBar extends StatelessWidget {
  final double totalMonth;
  final int filteredCount;
  final double totalFiltered;
  final NumberFormat formatter;

  const DecaissementSummaryBar({
    super.key,
    required this.totalMonth,
    required this.filteredCount,
    required this.totalFiltered,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _summaryChip(
            label: 'Dépenses Ce Mois',
            value: formatter.format(totalMonth),
            icon: Icons.calendar_month_outlined,
            color: AppColors.danger,
          ),
          const SizedBox(width: 12),
          _summaryChip(
            label: 'Sélection ($filteredCount)',
            value: formatter.format(totalFiltered),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.purple,
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool small = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: small ? 11 : 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
