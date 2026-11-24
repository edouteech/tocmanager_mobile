import 'package:flutter/material.dart';
import '../../models/date_filter_period.dart';
import '../../theme/app_theme.dart';
import '../../widgets/period_filter_modal.dart';

class VenteSearchAndSortBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSortSelected;

  const VenteSearchAndSortBar({
    super.key,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onClearSearch,
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
              controller: searchCtrl,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher (ticket N°, client, produit)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textMedium),
                        onPressed: onClearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Trier les ventes',
            onSelected: onSortSelected,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.sort_outlined, color: AppColors.primary, size: 20),
            ),
            itemBuilder: (_) => const [
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
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Montant décroissant'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'client_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Client (A-Z)'),
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

class VenteFilterChipsRow extends StatelessWidget {
  final DateFilterPeriod dateFilter;
  final bool onlyCredit;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectToday;
  final VoidCallback onSelectWeek;
  final VoidCallback onSelectMonth;
  final VoidCallback onToggleCredit;
  final ValueChanged<DateFilterPeriod> onCustomPeriod;

  const VenteFilterChipsRow({
    super.key,
    required this.dateFilter,
    required this.onlyCredit,
    required this.onSelectAll,
    required this.onSelectToday,
    required this.onSelectWeek,
    required this.onSelectMonth,
    required this.onToggleCredit,
    required this.onCustomPeriod,
  });

  bool get _isPresetCustom {
    final p = dateFilter.preset;
    return p != PeriodPreset.all &&
        p != PeriodPreset.today &&
        p != PeriodPreset.thisWeek &&
        p != PeriodPreset.thisMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('Tout', !onlyCredit && dateFilter.preset == PeriodPreset.all, onSelectAll),
            const SizedBox(width: 6),
            _buildChip('Aujourd\'hui', dateFilter.preset == PeriodPreset.today, onSelectToday),
            const SizedBox(width: 6),
            _buildChip('7 jours', dateFilter.preset == PeriodPreset.thisWeek, onSelectWeek),
            const SizedBox(width: 6),
            _buildChip('Ce mois', dateFilter.preset == PeriodPreset.thisMonth, onSelectMonth),
            const SizedBox(width: 6),
            FilterChip(
              label: const Text('À crédit'),
              selected: onlyCredit,
              onSelected: (_) => onToggleCredit(),
              selectedColor: AppColors.warningLight,
              checkmarkColor: AppColors.warning,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onlyCredit ? AppColors.warning : AppColors.textMedium,
              ),
            ),
            const SizedBox(width: 6),
            ActionChip(
              avatar: Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: _isPresetCustom ? AppColors.primary : AppColors.textMedium,
              ),
              label: Text(
                _isPresetCustom ? dateFilter.shortLabel : 'Période',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isPresetCustom ? AppColors.primary : AppColors.textMedium,
                ),
              ),
              backgroundColor: _isPresetCustom ? AppColors.primaryLight : AppColors.background,
              onPressed: () async {
                final picked = await PeriodFilterModal.show(context, current: dateFilter);
                if (picked != null) onCustomPeriod(picked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.primary : AppColors.textMedium,
      ),
    );
  }
}
