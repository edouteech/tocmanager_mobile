import 'package:flutter/material.dart';
import '../models/date_filter_period.dart';
import '../theme/app_theme.dart';

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
          _buildDragHandle(),
          _buildHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomRangeCard(),
                  const SizedBox(height: 16),
                  _buildSectionTitle(Icons.bolt, 'Raccourcis rapides'),
                  const SizedBox(height: 8),
                  _buildQuickPresetsWrap(),
                  const SizedBox(height: 20),
                  _buildSectionTitle(Icons.calendar_month, 'Sélectionner un mois précis'),
                  const SizedBox(height: 8),
                  _buildMonthSelectorCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle(Icons.pie_chart_outline, 'Trimestres & Semestres'),
                  const SizedBox(height: 8),
                  _buildQuarterAndSemesterCard(),
                  const SizedBox(height: 20),
                  _buildResetButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Filtrer par période',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
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

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomRangeCard() {
    final isCustom = widget.currentFilter.preset == PeriodPreset.customRange;
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
                const Text(
                  'Plage libre (Calendrier)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  isCustom
                      ? widget.currentFilter.label
                      : 'Choisir une date de début et de fin',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _pickCustomRange,
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

  Widget _buildQuickPresetsWrap() {
    final presets = [
      (PeriodPreset.today, 'Aujourd\'hui', Icons.today),
      (PeriodPreset.yesterday, 'Hier', Icons.history),
      (PeriodPreset.thisWeek, 'Cette semaine', Icons.view_week_outlined),
      (PeriodPreset.last7days, '7 derniers jours', Icons.timelapse),
      (PeriodPreset.thisMonth, 'Ce mois-ci', Icons.calendar_view_month),
      (PeriodPreset.lastMonth, 'Mois dernier', Icons.skip_previous_outlined),
      (PeriodPreset.thisYear, 'Cette année', Icons.calendar_today_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final isSelected = widget.currentFilter.preset == p.$1;
        return InkWell(
          onTap: () {
            DateFilterPeriod period;
            switch (p.$1) {
              case PeriodPreset.today:
                period = DateFilterPeriod.today();
                break;
              case PeriodPreset.yesterday:
                period = DateFilterPeriod.yesterday();
                break;
              case PeriodPreset.thisWeek:
                period = DateFilterPeriod.thisWeek();
                break;
              case PeriodPreset.last7days:
                period = DateFilterPeriod.last7days();
                break;
              case PeriodPreset.thisMonth:
                period = DateFilterPeriod.thisMonth();
                break;
              case PeriodPreset.lastMonth:
                period = DateFilterPeriod.lastMonth();
                break;
              case PeriodPreset.thisYear:
                period = DateFilterPeriod.thisYear();
                break;
              default:
                period = DateFilterPeriod.all();
            }
            Navigator.pop(context, period);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  p.$3,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textMedium,
                ),
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

  Widget _buildMonthSelectorCard() {
    final isCustomMonth = widget.currentFilter.preset == PeriodPreset.customMonth &&
        widget.currentFilter.selectedYear == _selectedYear &&
        widget.currentFilter.selectedMonth == _selectedMonth;

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
                      value: _selectedMonth,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: List.generate(12, (i) {
                        return DropdownMenuItem<int>(
                          value: i + 1,
                          child: Text(_monthNames[i]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
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
                      value: _selectedYear,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _availableYears.map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
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
              onPressed: () {
                Navigator.pop(
                  context,
                  DateFilterPeriod.customMonth(_selectedYear, _selectedMonth),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCustomMonth ? AppColors.primaryDark : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: Text(
                'Afficher ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterAndSemesterCard() {
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
                    value: _selectedYear,
                    isDense: true,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: _availableYears.map((y) {
                      return DropdownMenuItem<int>(value: y, child: Text('$y'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
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
              final isSelected = widget.currentFilter.preset == PeriodPreset.customQuarter &&
                  widget.currentFilter.selectedQuarter == q &&
                  widget.currentFilter.selectedYear == _selectedYear;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 6.0 : 0.0),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        DateFilterPeriod.customQuarter(_selectedYear, q),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: isSelected ? AppColors.primary : Colors.white,
                      foregroundColor: isSelected ? Colors.white : AppColors.textDark,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
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
              Expanded(
                child: _semesterButton(1, 'S1 (Jan - Juin)'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _semesterButton(2, 'S2 (Juil - Déc)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _semesterButton(int s, String title) {
    final isSelected = widget.currentFilter.preset == PeriodPreset.customSemester &&
        widget.currentFilter.selectedSemester == s &&
        widget.currentFilter.selectedYear == _selectedYear;

    return OutlinedButton(
      onPressed: () {
        Navigator.pop(
          context,
          DateFilterPeriod.customSemester(_selectedYear, s),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.textDark,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          Navigator.pop(context, DateFilterPeriod.all());
        },
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
    );
  }
}
