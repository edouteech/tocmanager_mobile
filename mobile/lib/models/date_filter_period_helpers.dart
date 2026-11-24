import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'date_filter_period.dart';

class DateFilterPeriodHelpers {
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 0, 0, 0);
  static DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTimeRange? computeEffectiveRange(DateFilterPeriod p) {
    final now = DateTime.now();
    switch (p.preset) {
      case PeriodPreset.all:
        return null;
      case PeriodPreset.today:
        return DateTimeRange(start: startOfDay(now), end: endOfDay(now));
      case PeriodPreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(start: startOfDay(y), end: endOfDay(y));
      case PeriodPreset.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: startOfDay(monday), end: endOfDay(monday.add(const Duration(days: 6))));
      case PeriodPreset.last7days:
        return DateTimeRange(start: startOfDay(now.subtract(const Duration(days: 7))), end: endOfDay(now));
      case PeriodPreset.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.lastMonth:
        final y = now.month == 1 ? now.year - 1 : now.year;
        final m = now.month == 1 ? 12 : now.month - 1;
        return DateTimeRange(start: DateTime(y, m, 1), end: DateTime(y, m + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.customMonth:
        final y = p.selectedYear ?? now.year;
        final m = p.selectedMonth ?? now.month;
        return DateTimeRange(start: DateTime(y, m, 1), end: DateTime(y, m + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.thisQuarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        return DateTimeRange(start: DateTime(now.year, (q - 1) * 3 + 1, 1), end: DateTime(now.year, q * 3 + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.customQuarter:
        final y = p.selectedYear ?? now.year;
        final q = p.selectedQuarter ?? 1;
        return DateTimeRange(start: DateTime(y, (q - 1) * 3 + 1, 1), end: DateTime(y, q * 3 + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.thisSemester:
        final s = now.month <= 6 ? 1 : 2;
        return DateTimeRange(start: DateTime(now.year, (s - 1) * 6 + 1, 1), end: DateTime(now.year, s * 6 + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.customSemester:
        final y = p.selectedYear ?? now.year;
        final s = p.selectedSemester ?? 1;
        return DateTimeRange(start: DateTime(y, (s - 1) * 6 + 1, 1), end: DateTime(y, s * 6 + 1, 0, 23, 59, 59, 999));
      case PeriodPreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: DateTime(now.year, 12, 31, 23, 59, 59, 999));
      case PeriodPreset.customYear:
        final y = p.selectedYear ?? now.year;
        return DateTimeRange(start: DateTime(y, 1, 1), end: DateTime(y, 12, 31, 23, 59, 59, 999));
      case PeriodPreset.customRange:
        if (p.customStart == null || p.customEnd == null) return null;
        return DateTimeRange(start: startOfDay(p.customStart!), end: endOfDay(p.customEnd!));
    }
  }

  static String computeShortLabel(DateFilterPeriod p) {
    final now = DateTime.now();
    switch (p.preset) {
      case PeriodPreset.all:
        return 'Toutes';
      case PeriodPreset.today:
        return 'Aujourd\'hui';
      case PeriodPreset.yesterday:
        return 'Hier';
      case PeriodPreset.thisWeek:
        return 'Cette semaine';
      case PeriodPreset.last7days:
        return '7 derniers jours';
      case PeriodPreset.thisMonth:
        return 'Ce mois-ci';
      case PeriodPreset.lastMonth:
        return 'Mois dernier';
      case PeriodPreset.customMonth:
        return formatMonthYear(p.selectedYear ?? now.year, p.selectedMonth ?? now.month);
      case PeriodPreset.thisQuarter:
        return 'T${((now.month - 1) ~/ 3) + 1} ${now.year}';
      case PeriodPreset.customQuarter:
        return 'T${p.selectedQuarter ?? 1} ${p.selectedYear ?? now.year}';
      case PeriodPreset.thisSemester:
        return 'S${now.month <= 6 ? 1 : 2} ${now.year}';
      case PeriodPreset.customSemester:
        return 'S${p.selectedSemester ?? 1} ${p.selectedYear ?? now.year}';
      case PeriodPreset.thisYear:
        return 'Cette année';
      case PeriodPreset.customYear:
        return '${p.selectedYear ?? now.year}';
      case PeriodPreset.customRange:
        if (p.customStart != null && p.customEnd != null) {
          final fmt = DateFormat('dd/MM/yyyy');
          return '${fmt.format(p.customStart!)} - ${fmt.format(p.customEnd!)}';
        }
        return 'Personnalisée';
    }
  }

  static String computeLabel(DateFilterPeriod p) {
    final range = p.effectiveRange;
    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy');
    switch (p.preset) {
      case PeriodPreset.all:
        return 'Tout l\'historique';
      case PeriodPreset.today:
        return 'Aujourd\'hui (${fmt.format(now)})';
      case PeriodPreset.yesterday:
        return 'Hier (${fmt.format(now.subtract(const Duration(days: 1)))})';
      case PeriodPreset.thisWeek:
        return range != null ? 'Cette semaine (${fmt.format(range.start)} au ${fmt.format(range.end)})' : 'Cette semaine';
      case PeriodPreset.last7days:
        return range != null ? '7 derniers jours (${fmt.format(range.start)} au ${fmt.format(range.end)})' : '7 derniers jours';
      case PeriodPreset.thisMonth:
        return 'Ce mois-ci (${formatMonthYear(now.year, now.month)})';
      case PeriodPreset.lastMonth:
        final y = now.month == 1 ? now.year - 1 : now.year;
        final m = now.month == 1 ? 12 : now.month - 1;
        return 'Mois dernier (${formatMonthYear(y, m)})';
      case PeriodPreset.customMonth:
        return 'Mois de ${formatMonthYear(p.selectedYear ?? now.year, p.selectedMonth ?? now.month)}';
      case PeriodPreset.thisQuarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        return '$q${ordinal(q)} Trimestre ${now.year}';
      case PeriodPreset.customQuarter:
        final q = p.selectedQuarter ?? 1;
        return '$q${ordinal(q)} Trimestre ${p.selectedYear ?? now.year}';
      case PeriodPreset.thisSemester:
        final s = now.month <= 6 ? 1 : 2;
        return '$s${ordinal(s)} Semestre ${now.year}';
      case PeriodPreset.customSemester:
        final s = p.selectedSemester ?? 1;
        return '$s${ordinal(s)} Semestre ${p.selectedYear ?? now.year}';
      case PeriodPreset.thisYear:
        return 'Année ${now.year}';
      case PeriodPreset.customYear:
        return 'Année ${p.selectedYear ?? now.year}';
      case PeriodPreset.customRange:
        return range != null ? 'Du ${fmt.format(range.start)} au ${fmt.format(range.end)}' : 'Période personnalisée';
    }
  }

  static String ordinal(int n) => n == 1 ? 'er' : 'e';

  static String formatMonthYear(int year, int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return (month >= 1 && month <= 12) ? '${months[month - 1]} $year' : '$month/$year';
  }
}
