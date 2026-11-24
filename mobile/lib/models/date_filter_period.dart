import 'package:flutter/material.dart';
import 'date_filter_period_helpers.dart';

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
  final int? selectedQuarter;
  final int? selectedSemester;

  const DateFilterPeriod({
    required this.preset,
    this.customStart,
    this.customEnd,
    this.selectedYear,
    this.selectedMonth,
    this.selectedQuarter,
    this.selectedSemester,
  });

  factory DateFilterPeriod.all() => const DateFilterPeriod(preset: PeriodPreset.all);
  factory DateFilterPeriod.today() => const DateFilterPeriod(preset: PeriodPreset.today);
  factory DateFilterPeriod.yesterday() => const DateFilterPeriod(preset: PeriodPreset.yesterday);
  factory DateFilterPeriod.thisWeek() => const DateFilterPeriod(preset: PeriodPreset.thisWeek);
  factory DateFilterPeriod.last7days() => const DateFilterPeriod(preset: PeriodPreset.last7days);
  factory DateFilterPeriod.thisMonth() => const DateFilterPeriod(preset: PeriodPreset.thisMonth);
  factory DateFilterPeriod.lastMonth() => const DateFilterPeriod(preset: PeriodPreset.lastMonth);

  factory DateFilterPeriod.customMonth(int year, int month) => DateFilterPeriod(
        preset: PeriodPreset.customMonth,
        selectedYear: year,
        selectedMonth: month,
      );

  factory DateFilterPeriod.thisQuarter() => const DateFilterPeriod(preset: PeriodPreset.thisQuarter);

  factory DateFilterPeriod.customQuarter(int year, int quarter) => DateFilterPeriod(
        preset: PeriodPreset.customQuarter,
        selectedYear: year,
        selectedQuarter: quarter,
      );

  factory DateFilterPeriod.thisSemester() => const DateFilterPeriod(preset: PeriodPreset.thisSemester);

  factory DateFilterPeriod.customSemester(int year, int semester) => DateFilterPeriod(
        preset: PeriodPreset.customSemester,
        selectedYear: year,
        selectedSemester: semester,
      );

  factory DateFilterPeriod.thisYear() => const DateFilterPeriod(preset: PeriodPreset.thisYear);

  factory DateFilterPeriod.customYear(int year) => DateFilterPeriod(
        preset: PeriodPreset.customYear,
        selectedYear: year,
      );

  factory DateFilterPeriod.customRange(DateTime start, DateTime end) => DateFilterPeriod(
        preset: PeriodPreset.customRange,
        customStart: start,
        customEnd: end,
      );

  DateTimeRange? get effectiveRange => DateFilterPeriodHelpers.computeEffectiveRange(this);

  bool matches(DateTime date) {
    if (preset == PeriodPreset.all) return true;
    final range = effectiveRange;
    if (range == null) return true;
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  String get shortLabel => DateFilterPeriodHelpers.computeShortLabel(this);
  String get label => DateFilterPeriodHelpers.computeLabel(this);

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
