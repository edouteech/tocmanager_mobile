import 'package:flutter/material.dart';
import '../models/date_filter_period.dart';
import '../theme/app_theme.dart';

class PeriodMonthSelectorCard extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final List<int> availableYears;
  final List<String> monthNames;
  final DateFilterPeriod currentFilter;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onApply;

  const PeriodMonthSelectorCard({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.availableYears,
    required this.monthNames,
    required this.currentFilter,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomMonth = currentFilter.preset == PeriodPreset.customMonth &&
        currentFilter.selectedYear == selectedYear &&
        currentFilter.selectedMonth == selectedMonth;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedMonth,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: List.generate(12, (i) {
                        return DropdownMenuItem<int>(value: i + 1, child: Text(monthNames[i]));
                      }),
                      onChanged: (val) {
                        if (val != null) onMonthChanged(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCustomMonth ? AppColors.primaryDark : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: Text(
                'Afficher ${monthNames[selectedMonth - 1]} $selectedYear',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
