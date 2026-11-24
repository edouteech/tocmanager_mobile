import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ApprovisionSearchAndSortBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const ApprovisionSearchAndSortBar({
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
                hintText: 'Rechercher (fournisseur, note)...',
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
            tooltip: 'Trier les approvisionnements',
            onSelected: onSortSelected,
            itemBuilder: (ctx) => const [
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
              PopupMenuItem(
                value: 'total_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Total le plus élevé'),
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

class ApprovisionPeriodFilterRow extends StatelessWidget {
  final String filterPeriod;
  final ValueChanged<String> onPeriodChanged;

  const ApprovisionPeriodFilterRow({
    super.key,
    required this.filterPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            const SizedBox(width: 6),
            _periodChip('À crédit', 'credit'),
          ],
        ),
      ),
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
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      onSelected: (val) {
        if (val) onPeriodChanged(type);
      },
    );
  }
}
