import 'package:flutter/material.dart';
import '../models/date_filter_period.dart';
import '../theme/app_theme.dart';

class PeriodQuarterSemesterCard extends StatelessWidget {
  final int selectedYear;
  final List<int> availableYears;
  final DateFilterPeriod currentFilter;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<DateFilterPeriod> onSelect;

  const PeriodQuarterSemesterCard({
    super.key,
    required this.selectedYear,
    required this.availableYears,
    required this.currentFilter,
    required this.onYearChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Année de référence :',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isDense: true,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: availableYears.map((y) {
                      return DropdownMenuItem<int>(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onYearChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Trimestres (3 mois) :',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(4, (i) {
              final q = i + 1;
              final isSelected = currentFilter.preset == PeriodPreset.customQuarter &&
                  currentFilter.selectedQuarter == q &&
                  currentFilter.selectedYear == selectedYear;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 6.0 : 0.0),
                  child: OutlinedButton(
                    onPressed: () => onSelect(DateFilterPeriod.customQuarter(selectedYear, q)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: isSelected ? AppColors.primary : Colors.white,
                      foregroundColor: isSelected ? Colors.white : AppColors.textDark,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'T$q',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Text(
            'Semestres (6 mois) :',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _semesterButton(1, 'S1 (Jan - Juin)')),
              const SizedBox(width: 8),
              Expanded(child: _semesterButton(2, 'S2 (Juil - Déc)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _semesterButton(int s, String title) {
    final isSelected = currentFilter.preset == PeriodPreset.customSemester &&
        currentFilter.selectedSemester == s &&
        currentFilter.selectedYear == selectedYear;
    return OutlinedButton(
      onPressed: () => onSelect(DateFilterPeriod.customSemester(selectedYear, s)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.textDark,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        title,
        style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
