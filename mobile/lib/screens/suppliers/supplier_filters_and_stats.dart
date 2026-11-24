import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class SupplierStatsBar extends StatelessWidget {
  final int supplierCount;
  final double totalDettes;
  final NumberFormat formatter;

  const SupplierStatsBar({
    super.key,
    required this.supplierCount,
    required this.totalDettes,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Fournisseurs', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text('$supplierCount',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dettes Impayées', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                  const SizedBox(height: 2),
                  Text(formatter.format(totalDettes),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierSearchAndSortBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const SupplierSearchAndSortBar({
    super.key,
    required this.onSearchChanged,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un fournisseur (société, contact)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.sort_outlined, color: AppColors.primary, size: 20),
            ),
            tooltip: 'Trier les fournisseurs',
            onSelected: onSortSelected,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'debt_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Dette la plus élevée'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Nom (A - Z)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textMedium),
                    SizedBox(width: 8),
                    Text('Plus récents'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SupplierFilterChipsRow extends StatelessWidget {
  final String filterCategory;
  final int totalCount;
  final int debtCount;
  final int paidCount;
  final ValueChanged<String> onFilterChanged;

  const SupplierFilterChipsRow({
    super.key,
    required this.filterCategory,
    required this.totalCount,
    required this.debtCount,
    required this.paidCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Tous ($totalCount)', 'all'),
            const SizedBox(width: 6),
            _filterChip('Avec dette ($debtCount)', 'debt', isDanger: true),
            const SizedBox(width: 6),
            _filterChip('À jour ($paidCount)', 'paid', isSuccess: true),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String category, {bool isDanger = false, bool isSuccess = false}) {
    final selected = filterCategory == category;
    final activeColor = isDanger ? AppColors.danger : isSuccess ? AppColors.success : AppColors.primary;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: selected,
      selectedColor: activeColor,
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? activeColor : AppColors.divider),
      onSelected: (val) {
        if (val) onFilterChanged(category);
      },
    );
  }
}

class SupplierEmptyState extends StatelessWidget {
  const SupplierEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 12),
          const Text('Aucun fournisseur trouvé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos fournisseurs pour le suivi de vos commandes',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
