import 'package:flutter/material.dart';
import '../models/date_filter_period.dart';
import '../theme/app_theme.dart';
import 'period_filter_calendar_cards.dart';
import 'period_filter_presets.dart';
import 'period_quarter_semester_card.dart';

class PeriodFilterModal extends StatefulWidget {
  final DateFilterPeriod currentFilter;

  const PeriodFilterModal({
    super.key,
    required this.currentFilter,
  });

  static Future<DateFilterPeriod?> show(
    BuildContext context, {
    required DateFilterPeriod current,
  }) {
    return showModalBottomSheet<DateFilterPeriod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PeriodFilterModal(currentFilter: current),
    );
  }

  @override
  State<PeriodFilterModal> createState() => _PeriodFilterModalState();
}

class _PeriodFilterModalState extends State<PeriodFilterModal> {
  late int _selectedYear;
  late int _selectedMonth;

  static const _monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = widget.currentFilter.selectedYear ?? now.year;
    _selectedMonth = widget.currentFilter.selectedMonth ?? now.month;
  }

  List<int> get _availableYears {
    final current = DateTime.now().year;
    return [current - 2, current - 1, current, current + 1];
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = widget.currentFilter.effectiveRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      helpText: 'Sélectionner une plage de dates',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      saveText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      Navigator.pop(
        context,
        DateFilterPeriod.customRange(picked.start, picked.end),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildPeriodModalDragHandle(),
          buildPeriodModalHeader(context),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PeriodCustomRangeCard(
                    currentFilter: widget.currentFilter,
                    onPickRange: _pickCustomRange,
                  ),
                  const SizedBox(height: 16),
                  buildPeriodSectionTitle(Icons.bolt, 'Raccourcis rapides'),
                  const SizedBox(height: 8),
                  PeriodQuickPresetsWrap(
                    activePreset: widget.currentFilter.preset,
                    onSelect: (period) => Navigator.pop(context, period),
                  ),
                  const SizedBox(height: 20),
                  buildPeriodSectionTitle(Icons.calendar_month, 'Sélectionner un mois précis'),
                  const SizedBox(height: 8),
                  PeriodMonthSelectorCard(
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    availableYears: _availableYears,
                    monthNames: _monthNames,
                    currentFilter: widget.currentFilter,
                    onMonthChanged: (m) => setState(() => _selectedMonth = m),
                    onYearChanged: (y) => setState(() => _selectedYear = y),
                    onApply: () => Navigator.pop(
                      context,
                      DateFilterPeriod.customMonth(_selectedYear, _selectedMonth),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildPeriodSectionTitle(Icons.pie_chart_outline, 'Trimestres & Semestres'),
                  const SizedBox(height: 8),
                  PeriodQuarterSemesterCard(
                    selectedYear: _selectedYear,
                    availableYears: _availableYears,
                    currentFilter: widget.currentFilter,
                    onYearChanged: (y) => setState(() => _selectedYear = y),
                    onSelect: (period) => Navigator.pop(context, period),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context, DateFilterPeriod.all()),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMedium,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text(
                        'Réinitialiser (Afficher tout l\'historique)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
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
