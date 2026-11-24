import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CategoryStatsBar extends StatelessWidget {
  final int totalCategories;
  final int categorizedProductsCount;

  const CategoryStatsBar({
    super.key,
    required this.totalCategories,
    required this.categorizedProductsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                  const Text('Total Catégories', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text(
                    '$totalCategories',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Produits Catégorisés', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text(
                    '$categorizedProductsCount',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategorySearchAndSortBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const CategorySearchAndSortBar({
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
                hintText: 'Rechercher une catégorie...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sort_outlined, color: AppColors.primary, size: 20),
            ),
            tooltip: 'Trier les catégories',
            onSelected: onSortSelected,
            itemBuilder: (ctx) => const [
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
                value: 'products_desc',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Plus de produits'),
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

class CategoryFilterChipsRow extends StatelessWidget {
  final String filterType;
  final int totalCount;
  final int withProductsCount;
  final int emptyCount;
  final ValueChanged<String> onFilterChanged;

  const CategoryFilterChipsRow({
    super.key,
    required this.filterType,
    required this.totalCount,
    required this.withProductsCount,
    required this.emptyCount,
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
            _filterChip('Toutes ($totalCount)', 'all'),
            const SizedBox(width: 6),
            _filterChip('Avec produits ($withProductsCount)', 'with_products', isSuccess: true),
            const SizedBox(width: 6),
            _filterChip('Vides ($emptyCount)', 'empty'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String type, {bool isSuccess = false}) {
    final selected = filterType == type;
    final activeColor = isSuccess ? AppColors.success : AppColors.primary;

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
        if (val) onFilterChanged(type);
      },
    );
  }
}
