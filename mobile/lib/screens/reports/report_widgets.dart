import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/date_filter_period.dart';
import '../../theme/app_theme.dart';
import '../../widgets/period_filter_modal.dart';

String reportCurrencySymbol(String code) {
  switch (code.toUpperCase()) {
    case 'XAF':
      return 'FCFA';
    case 'EUR':
      return '€';
    case 'USD':
      return r'$';
    case 'GHS':
      return 'GH₵';
    case 'NGN':
      return '₦';
    case 'GNF':
      return 'GNF';
    case 'XOF':
    case 'FCFA':
    default:
      return 'F';
  }
}

Widget buildReportSectionHeader(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
      ),
    ],
  );
}

class ReportPeriodFilterBar extends StatelessWidget {
  final DateFilterPeriod period;
  final ValueChanged<DateFilterPeriod> onChanged;

  const ReportPeriodFilterBar({
    super.key,
    required this.period,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomActive = period.preset != PeriodPreset.all &&
        period.preset != PeriodPreset.today &&
        period.preset != PeriodPreset.thisWeek &&
        period.preset != PeriodPreset.thisMonth &&
        period.preset != PeriodPreset.thisYear;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _periodChip('Aujourd\'hui', period.preset == PeriodPreset.today,
              () => onChanged(DateFilterPeriod.today())),
          const SizedBox(width: 8),
          _periodChip('Cette semaine', period.preset == PeriodPreset.thisWeek,
              () => onChanged(DateFilterPeriod.thisWeek())),
          const SizedBox(width: 8),
          _periodChip('Ce mois-ci', period.preset == PeriodPreset.thisMonth,
              () => onChanged(DateFilterPeriod.thisMonth())),
          const SizedBox(width: 8),
          _periodChip('Cette année', period.preset == PeriodPreset.thisYear,
              () => onChanged(DateFilterPeriod.thisYear())),
          const SizedBox(width: 8),
          _periodChip('Tout l\'historique', period.preset == PeriodPreset.all,
              () => onChanged(DateFilterPeriod.all())),
          const SizedBox(width: 8),
          ActionChip(
            avatar: Icon(
              isCustomActive ? Icons.event_available : Icons.date_range,
              size: 16,
              color: isCustomActive ? Colors.white : AppColors.primary,
            ),
            label: Text(
              isCustomActive ? period.shortLabel : 'Période...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCustomActive ? FontWeight.w700 : FontWeight.w600,
                color: isCustomActive ? Colors.white : AppColors.primaryDark,
              ),
            ),
            backgroundColor: isCustomActive ? AppColors.primary : AppColors.primarySurface,
            side: BorderSide(
              color: isCustomActive ? AppColors.primary : AppColors.primary.withAlpha(50),
            ),
            onPressed: () async {
              final selected = await PeriodFilterModal.show(context, current: period);
              if (selected != null) onChanged(selected);
            },
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
      onSelected: (_) => onTap(),
    );
  }
}

class ReportKpiGrid extends StatelessWidget {
  final double ca;
  final double marge;
  final double tauxMarge;
  final double depenses;
  final double tresorerie;
  final NumberFormat formatter;

  const ReportKpiGrid({
    super.key,
    required this.ca,
    required this.marge,
    required this.tauxMarge,
    required this.depenses,
    required this.tresorerie,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _kpiCard('Chiffre d\'Affaires', formatter.format(ca), Icons.trending_up,
                AppColors.success, sub: 'Recettes des ventes'),
            const SizedBox(width: 10),
            _kpiCard('Marge Brute', formatter.format(marge), Icons.pie_chart_outline,
                AppColors.primary, sub: '${tauxMarge.toStringAsFixed(1)}% du CA'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _kpiCard('Total Dépenses', formatter.format(depenses), Icons.trending_down,
                AppColors.danger, sub: 'Décaissements'),
            const SizedBox(width: 10),
            _kpiCard(
              'Trésorerie Nette',
              formatter.format(tresorerie),
              Icons.account_balance_wallet_outlined,
              tresorerie >= 0 ? AppColors.success : AppColors.danger,
              sub: 'CA - Dépenses',
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, {String? sub}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ],
          ],
        ),
      ),
    );
  }
}
