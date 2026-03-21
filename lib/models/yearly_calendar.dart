import 'prayer_times.dart';

/// Holds a full 12-month prayer calendar for a single mosque.
/// Parsed from Mawaqit confData.calendar field.
class YearlyCalendar {
  /// calendar[monthIndex (0-11)][dayOfMonth (1-based)] = [fajr, sunrise, dhuhr, asr, maghrib, isha]
  final List<Map<int, List<String>>> months;
  final DateTime fetchedAt;
  final String mosqueSlug;

  const YearlyCalendar({
    required this.months,
    required this.fetchedAt,
    required this.mosqueSlug,
  });

  DailyPrayerTimes? getDay(DateTime date) {
    if (date.month < 1 || date.month > 12) return null;
    final monthIndex = date.month - 1;
    if (monthIndex >= months.length) return null;
    final month = months[monthIndex];
    final times = month[date.day];
    if (times == null || times.length < 6) return null;
    return DailyPrayerTimes.fromCalendarEntry(date, times);
  }

  DailyPrayerTimes? get today => getDay(DateTime.now());

  DailyPrayerTimes? get tomorrow =>
      getDay(DateTime.now().add(const Duration(days: 1)));

  /// Parse from Mawaqit confData calendar structure.
  /// confData.calendar is List<Map<String, List<dynamic>>>
  factory YearlyCalendar.fromConfData(
    List<dynamic> calendarData,
    String mosqueSlug,
  ) {
    final months = <Map<int, List<String>>>[];

    for (final monthData in calendarData) {
      final month = <int, List<String>>{};
      if (monthData is Map) {
        for (final entry in monthData.entries) {
          final dayNum = int.tryParse(entry.key.toString());
          if (dayNum == null) continue;
          final times = (entry.value as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          month[dayNum] = times;
        }
      }
      months.add(month);
    }

    return YearlyCalendar(
      months: months,
      fetchedAt: DateTime.now(),
      mosqueSlug: mosqueSlug,
    );
  }

  Map<String, dynamic> toJson() {
    final monthsList = months.map((month) {
      final m = <String, dynamic>{};
      for (final e in month.entries) {
        m[e.key.toString()] = e.value;
      }
      return m;
    }).toList();

    return {
      'months': monthsList,
      'fetchedAt': fetchedAt.toIso8601String(),
      'mosqueSlug': mosqueSlug,
    };
  }

  factory YearlyCalendar.fromJson(Map<String, dynamic> json) {
    final monthsList = (json['months'] as List<dynamic>).map((monthData) {
      final month = <int, List<String>>{};
      if (monthData is Map) {
        for (final entry in monthData.entries) {
          final dayNum = int.tryParse(entry.key.toString());
          if (dayNum == null) continue;
          final times = (entry.value as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          month[dayNum] = times;
        }
      }
      return month;
    }).toList();

    return YearlyCalendar(
      months: monthsList,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      mosqueSlug: json['mosqueSlug'] as String,
    );
  }
}
