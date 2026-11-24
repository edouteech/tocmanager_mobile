import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/approvisionnement.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';

String approvisionnementPeriodLabel(String filterPeriod) {
  if (filterPeriod == 'today') return 'Aujourd\'hui';
  if (filterPeriod == 'yesterday') return 'Hier';
  if (filterPeriod == 'month') return 'Ce mois-ci';
  if (filterPeriod == 'credit') return 'Approvisionnements à crédit';
  return 'Toutes les périodes';
}

List<Approvisionnement> filterAndSortApprovisionnements(
  List<Approvisionnement> allItems, {
  int? filterProductId,
  required String filterPeriod,
  required String search,
  required String sortBy,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final filtered = allItems.where((a) {
    if (filterProductId != null && a.productId != filterProductId) return false;
    final aDate = DateTime(a.date.year, a.date.month, a.date.day);
    if (filterPeriod == 'today' && !aDate.isAtSameMomentAs(today)) return false;
    if (filterPeriod == 'yesterday' && !aDate.isAtSameMomentAs(yesterday)) return false;
    if (filterPeriod == 'month' && (a.date.year != now.year || a.date.month != now.month)) return false;
    if (filterPeriod == 'credit' && !a.isCredit) return false;

    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      final matchSupp = (a.supplier ?? '').toLowerCase().contains(q);
      final matchNotes = (a.notes ?? '').toLowerCase().contains(q);
      if (!matchSupp && !matchNotes) return false;
    }
    return true;
  }).toList();

  if (sortBy == 'total_desc') {
    filtered.sort((a, b) => b.total.compareTo(a.total));
  } else if (sortBy == 'recent') {
    filtered.sort((a, b) => b.date.compareTo(a.date));
  }

  return filtered;
}

class ApprovisionSummaryBar extends StatelessWidget {
  final int totalCount;
  final double totalAmount;
  final NumberFormat formatter;

  const ApprovisionSummaryBar({
    super.key,
    required this.totalCount,
    required this.totalAmount,
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
            label: 'Total entrées',
            value: '$totalCount',
            icon: Icons.arrow_downward,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _summaryChip(
            label: 'Montant total',
            value: formatter.format(totalAmount),
            icon: Icons.show_chart,
            color: AppColors.primary,
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

class ApprovisionProductFilterRow extends StatelessWidget {
  final int? filterProductId;
  final List<Product> products;
  final ValueChanged<int?> onProductSelected;

  const ApprovisionProductFilterRow({
    super.key,
    required this.filterProductId,
    required this.products,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Tous'),
            ...products.map((p) => _filterChip(p.id, p.name)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int? productId, String label) {
    final selected = filterProductId == productId;
    return GestureDetector(
      onTap: () => onProductSelected(productId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMedium,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
