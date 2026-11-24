import 'package:flutter/material.dart';
import '../models/date_filter_period.dart';
import '../theme/app_theme.dart';

Widget buildPeriodModalDragHandle() {
  return Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.divider,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget buildPeriodModalHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
    child: Row(
      children: [
        const Icon(Icons.date_range, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Filtrer par période',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMedium),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Fermer',
        ),
      ],
    ),
  );
}

Widget buildPeriodSectionTitle(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, size: 16, color: AppColors.primaryDark),
      const SizedBox(width: 6),
      Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
    ],
  );
}

class PeriodCustomRangeCard extends StatelessWidget {
  final DateFilterPeriod currentFilter;
  final VoidCallback onPickRange;

  const PeriodCustomRangeCard({
    super.key,
    required this.currentFilter,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = currentFilter.preset == PeriodPreset.customRange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCustom ? AppColors.primarySurface : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCustom ? AppColors.primary : AppColors.divider,
          width: isCustom ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_calendar_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plage libre (Calendrier)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  isCustom ? currentFilter.label : 'Choisir une date de début et de fin',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPickRange,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Choisir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class PeriodQuickPresetsWrap extends StatelessWidget {
  final PeriodPreset activePreset;
  final ValueChanged<DateFilterPeriod> onSelect;

  const PeriodQuickPresetsWrap({
    super.key,
    required this.activePreset,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [
      (PeriodPreset.today, 'Aujourd\'hui', Icons.today, DateFilterPeriod.today),
      (PeriodPreset.yesterday, 'Hier', Icons.history, DateFilterPeriod.yesterday),
      (PeriodPreset.thisWeek, 'Cette semaine', Icons.view_week_outlined, DateFilterPeriod.thisWeek),
      (PeriodPreset.last7days, '7 derniers jours', Icons.timelapse, DateFilterPeriod.last7days),
      (PeriodPreset.thisMonth, 'Ce mois-ci', Icons.calendar_view_month, DateFilterPeriod.thisMonth),
      (PeriodPreset.lastMonth, 'Mois dernier', Icons.skip_previous_outlined, DateFilterPeriod.lastMonth),
      (PeriodPreset.thisYear, 'Cette année', Icons.calendar_today_outlined, DateFilterPeriod.thisYear),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final isSelected = activePreset == p.$1;
        return InkWell(
          onTap: () => onSelect(p.$4()),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(p.$3, size: 14, color: isSelected ? Colors.white : AppColors.textMedium),
                const SizedBox(width: 5),
                Text(
                  p.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
