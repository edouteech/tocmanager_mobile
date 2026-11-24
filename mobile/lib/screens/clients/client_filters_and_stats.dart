import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class ClientStatsBar extends StatelessWidget {
  final int totalClients;
  final double totalCreances;
  final double totalAvoirs;
  final NumberFormat formatter;

  const ClientStatsBar({
    super.key,
    required this.totalClients,
    required this.totalCreances,
    required this.totalAvoirs,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _box('Total Clients', '$totalClients', AppColors.primarySurface, AppColors.primary, AppColors.textDark, 16),
          const SizedBox(width: 6),
          _box('Créances (Dettes)', formatter.format(totalCreances), AppColors.warning.withAlpha(20),
              AppColors.warning, AppColors.warning, 13, labelColor: AppColors.warning),
          const SizedBox(width: 6),
          _box('Avoirs Clients', formatter.format(totalAvoirs), AppColors.purple.withAlpha(20), AppColors.purple,
              AppColors.purple, 13, labelColor: AppColors.purple),
        ],
      ),
    );
  }

  Widget _box(
    String label,
    String value,
    Color bg,
    Color borderColor,
    Color valueColor,
    double fontSize, {
    Color labelColor = AppColors.textMedium,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: valueColor)),
          ],
        ),
      ),
    );
  }
}

class ClientSearchAndSortBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const ClientSearchAndSortBar({
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
                hintText: 'Rechercher un client (nom, téléphone)...',
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
            tooltip: 'Trier les clients',
            onSelected: onSortSelected,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'debt_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Créance la plus élevée'),
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

class ClientFilterChipsRow extends StatelessWidget {
  final String filterCategory;
  final int totalCount;
  final int debtCount;
  final int avoirCount;
  final int paidCount;
  final ValueChanged<String> onFilterChanged;

  const ClientFilterChipsRow({
    super.key,
    required this.filterCategory,
    required this.totalCount,
    required this.debtCount,
    required this.avoirCount,
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
            _filterChip('Avec créance ($debtCount)', 'debt', isWarning: true),
            const SizedBox(width: 6),
            _filterChip('Avec avoir ($avoirCount)', 'avoir', customColor: AppColors.purple),
            const SizedBox(width: 6),
            _filterChip('À jour ($paidCount)', 'paid', isSuccess: true),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String category, {bool isWarning = false, bool isSuccess = false, Color? customColor}) {
    final isSelected = filterCategory == category;
    Color activeColor = customColor ?? AppColors.primary;
    if (isWarning) activeColor = AppColors.warning;
    if (isSuccess) activeColor = AppColors.success;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(category),
      selectedColor: activeColor,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class ClientEmptyState extends StatelessWidget {
  const ClientEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 12),
          const Text('Aucun client trouvé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos clients pour suivre les créances',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
