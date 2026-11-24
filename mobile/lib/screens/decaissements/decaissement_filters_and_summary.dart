import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'decaissement_filter_helpers.dart';

class DecaissementSearchAndSortBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const DecaissementSearchAndSortBar({
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
                hintText: 'Rechercher une dépense (motif, bénéficiaire)...',
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
              child: const Icon(Icons.sort_outlined, color: AppColors.danger, size: 20),
            ),
            tooltip: 'Trier les dépenses',
            onSelected: onSortSelected,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textMedium),
                    SizedBox(width: 8),
                    Text('Plus récentes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Montant le plus élevé'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category_asc',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Catégorie (A - Z)'),
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

class DecaissementPeriodAndCategoryFilters extends StatelessWidget {
  final String filterPeriod;
  final String? filterCategory;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String?> onCategoryChanged;

  const DecaissementPeriodAndCategoryFilters({
    super.key,
    required this.filterPeriod,
    required this.filterCategory,
    required this.onPeriodChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodChip('Toutes', 'all'),
                const SizedBox(width: 6),
                _periodChip('Aujourd\'hui', 'today'),
                const SizedBox(width: 6),
                _periodChip('Hier', 'yesterday'),
                const SizedBox(width: 6),
                _periodChip('Ce mois-ci', 'month'),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip(null, 'Tous'),
                ...kDecaissementCategories.map((c) => _categoryChip(c, c)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodChip(String label, String type) {
    final selected = filterPeriod == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.danger,
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? AppColors.danger : AppColors.divider),
      onSelected: (val) {
        if (val) onPeriodChanged(type);
      },
    );
  }

  Widget _categoryChip(String? cat, String label) {
    final selected = filterCategory == cat;
    return GestureDetector(
      onTap: () => onCategoryChanged(cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.danger : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.danger : AppColors.divider),
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
