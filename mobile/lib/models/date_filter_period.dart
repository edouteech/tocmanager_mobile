import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PeriodPreset {
  all,
  today,
  yesterday,
  thisWeek,
  last7days,
  thisMonth,
  lastMonth,
  customMonth,
  thisQuarter,
  customQuarter,
  thisSemester,
  customSemester,
  thisYear,
  customYear,
  customRange,
}

class DateFilterPeriod {
  final PeriodPreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedQuarter; // 1..4
  final int? selectedSemester; // 1..2

  const DateFilterPeriod({
    required this.preset,
    this.customStart,
    this.customEnd,
    this.selectedYear,
    this.selectedMonth,
    this.selectedQuarter,
    this.selectedSemester,
  });

  factory DateFilterPeriod.all() =>
      const DateFilterPeriod(preset: PeriodPreset.all);

  factory DateFilterPeriod.today() =>
      const DateFilterPeriod(preset: PeriodPreset.today);

  factory DateFilterPeriod.yesterday() =>
      const DateFilterPeriod(preset: PeriodPreset.yesterday);

  factory DateFilterPeriod.thisWeek() =>
      const DateFilterPeriod(preset: PeriodPreset.thisWeek);

  factory DateFilterPeriod.last7days() =>
      const DateFilterPeriod(preset: PeriodPreset.last7days);

  factory DateFilterPeriod.thisMonth() =>
      const DateFilterPeriod(preset: PeriodPreset.thisMonth);

  factory DateFilterPeriod.lastMonth() =>
      const DateFilterPeriod(preset: PeriodPreset.lastMonth);

  factory DateFilterPeriod.customMonth(int year, int month) => DateFilterPeriod(
        preset: PeriodPreset.customMonth,
        selectedYear: year,
        selectedMonth: month,
      );

  factory DateFilterPeriod.thisQuarter() =>
      const DateFilterPeriod(preset: PeriodPreset.thisQuarter);

  factory DateFilterPeriod.customQuarter(int year, int quarter) =>
      DateFilterPeriod(
        preset: PeriodPreset.customQuarter,
        selectedYear: year,
        selectedQuarter: quarter,
      );

  factory DateFilterPeriod.thisSemester() =>
      const DateFilterPeriod(preset: PeriodPreset.thisSemester);

  factory DateFilterPeriod.customSemester(int year, int semester) =>
      DateFilterPeriod(
        preset: PeriodPreset.customSemester,
        selectedYear: year,
        selectedSemester: semester,
      );

  factory DateFilterPeriod.thisYear() =>
      const DateFilterPeriod(preset: PeriodPreset.thisYear);

  factory DateFilterPeriod.customYear(int year) => DateFilterPeriod(
        preset: PeriodPreset.customYear,
        selectedYear: year,
      );

  factory DateFilterPeriod.customRange(DateTime start, DateTime end) =>
      DateFilterPeriod(
        preset: PeriodPreset.customRange,
        customStart: start,
        customEnd: end,
      );

  static DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 0, 0, 0);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// Renvoie la plage [start, end] effective selon le préréglage
  DateTimeRange? get effectiveRange {
    final now = DateTime.now();

    switch (preset) {
      case PeriodPreset.all:
        return null;

      case PeriodPreset.today:
        return DateTimeRange(start: _startOfDay(now), end: _endOfDay(now));

      case PeriodPreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(start: _startOfDay(y), end: _endOfDay(y));

      case PeriodPreset.thisWeek:
        // Lundi = 1, Dimanche = 7
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return DateTimeRange(start: _startOfDay(monday), end: _endOfDay(sunday));

      case PeriodPreset.last7days:
        final start = now.subtract(const Duration(days: 7));
        return DateTimeRange(start: _startOfDay(start), end: _endOfDay(now));

      case PeriodPreset.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.lastMonth:
        final y = now.month == 1 ? now.year - 1 : now.year;
        final m = now.month == 1 ? 12 : now.month - 1;
        final start = DateTime(y, m, 1, 0, 0, 0);
        final end = DateTime(y, m + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.customMonth:
        final y = selectedYear ?? now.year;
        final m = selectedMonth ?? now.month;
        final start = DateTime(y, m, 1, 0, 0, 0);
        final end = DateTime(y, m + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.thisQuarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (q - 1) * 3 + 1;
        final endMonth = q * 3;
        final start = DateTime(now.year, startMonth, 1, 0, 0, 0);
        final end = DateTime(now.year, endMonth + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.customQuarter:
        final y = selectedYear ?? now.year;
        final q = selectedQuarter ?? 1;
        final startMonth = (q - 1) * 3 + 1;
        final endMonth = q * 3;
        final start = DateTime(y, startMonth, 1, 0, 0, 0);
        final end = DateTime(y, endMonth + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.thisSemester:
        final s = now.month <= 6 ? 1 : 2;
        final startMonth = (s - 1) * 6 + 1;
        final endMonth = s * 6;
        final start = DateTime(now.year, startMonth, 1, 0, 0, 0);
        final end = DateTime(now.year, endMonth + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.customSemester:
        final y = selectedYear ?? now.year;
        final s = selectedSemester ?? 1;
        final startMonth = (s - 1) * 6 + 1;
        final endMonth = s * 6;
        final start = DateTime(y, startMonth, 1, 0, 0, 0);
        final end = DateTime(y, endMonth + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.customYear:
        final y = selectedYear ?? now.year;
        final start = DateTime(y, 1, 1, 0, 0, 0);
        final end = DateTime(y, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case PeriodPreset.customRange:
        if (customStart == null || customEnd == null) return null;
        return DateTimeRange(
          start: _startOfDay(customStart!),
          end: _endOfDay(customEnd!),
        );
    }
  }

  /// Détermine si une date donnée correspond au filtre sélectionné
  bool matches(DateTime date) {
    if (preset == PeriodPreset.all) return true;
    final range = effectiveRange;
    if (range == null) return true;
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  /// Libellé court pour les boutons et puces
  String get shortLabel {
    final now = DateTime.now();
    switch (preset) {
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
        final y = selectedYear ?? now.year;
        final m = selectedMonth ?? now.month;
        return _formatMonthYear(y, m);
      case PeriodPreset.thisQuarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        return 'T$q ${now.year}';
      case PeriodPreset.customQuarter:
        return 'T${selectedQuarter ?? 1} ${selectedYear ?? now.year}';
      case PeriodPreset.thisSemester:
        final s = now.month <= 6 ? 1 : 2;
        return 'S$s ${now.year}';
      case PeriodPreset.customSemester:
        return 'S${selectedSemester ?? 1} ${selectedYear ?? now.year}';
      case PeriodPreset.thisYear:
        return 'Cette année';
      case PeriodPreset.customYear:
        return '${selectedYear ?? now.year}';
      case PeriodPreset.customRange:
        if (customStart != null && customEnd != null) {
          final fmt = DateFormat('dd/MM/yyyy');
          return '${fmt.format(customStart!)} - ${fmt.format(customEnd!)}';
        }
        return 'Personnalisée';
    }
  }

  /// Libellé détaillé pour les en-têtes et les exports PDF / Excel
  String get label {
    final range = effectiveRange;
    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy');

    switch (preset) {
      case PeriodPreset.all:
        return 'Tout l\'historique';
      case PeriodPreset.today:
        return 'Aujourd\'hui (${fmt.format(now)})';
      case PeriodPreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return 'Hier (${fmt.format(y)})';
      case PeriodPreset.thisWeek:
        if (range != null) {
          return 'Cette semaine (${fmt.format(range.start)} au ${fmt.format(range.end)})';
        }
        return 'Cette semaine';
      case PeriodPreset.last7days:
        if (range != null) {
          return '7 derniers jours (${fmt.format(range.start)} au ${fmt.format(range.end)})';
        }
        return '7 derniers jours';
      case PeriodPreset.thisMonth:
        return 'Ce mois-ci (${_formatMonthYear(now.year, now.month)})';
      case PeriodPreset.lastMonth:
        final y = now.month == 1 ? now.year - 1 : now.year;
        final m = now.month == 1 ? 12 : now.month - 1;
        return 'Mois dernier (${_formatMonthYear(y, m)})';
      case PeriodPreset.customMonth:
        final y = selectedYear ?? now.year;
        final m = selectedMonth ?? now.month;
        return 'Mois de ${_formatMonthYear(y, m)}';
      case PeriodPreset.thisQuarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        return '$q${_ordinal(q)} Trimestre ${now.year}';
      case PeriodPreset.customQuarter:
        final q = selectedQuarter ?? 1;
        final y = selectedYear ?? now.year;
        return '$q${_ordinal(q)} Trimestre $y';
      case PeriodPreset.thisSemester:
        final s = now.month <= 6 ? 1 : 2;
        return '$s${_ordinal(s)} Semestre ${now.year}';
      case PeriodPreset.customSemester:
        final s = selectedSemester ?? 1;
        final y = selectedYear ?? now.year;
        return '$s${_ordinal(s)} Semestre $y';
      case PeriodPreset.thisYear:
        return 'Année ${now.year}';
      case PeriodPreset.customYear:
        return 'Année ${selectedYear ?? now.year}';
      case PeriodPreset.customRange:
        if (range != null) {
          return 'Du ${fmt.format(range.start)} au ${fmt.format(range.end)}';
        }
        return 'Période personnalisée';
    }
  }

  static String _ordinal(int n) => n == 1 ? 'er' : 'e';

  static String _formatMonthYear(int year, int month) {
    const months = [
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
      'Décembre'
    ];
    if (month >= 1 && month <= 12) {
      return '${months[month - 1]} $year';
    }
    return '$month/$year';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateFilterPeriod &&
        other.preset == preset &&
        other.customStart == customStart &&
        other.customEnd == customEnd &&
        other.selectedYear == selectedYear &&
        other.selectedMonth == selectedMonth &&
        other.selectedQuarter == selectedQuarter &&
        other.selectedSemester == selectedSemester;
  }

  @override
  int get hashCode => Object.hash(
        preset,
        customStart,
        customEnd,
        selectedYear,
        selectedMonth,
        selectedQuarter,
        selectedSemester,
      );
}
