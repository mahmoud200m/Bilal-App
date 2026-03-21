import 'package:intl/intl.dart';
import 'timing_type.dart';

class DailyPrayerTimes {
  final DateTime date;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory DailyPrayerTimes.fromCalendarEntry(
    DateTime date,
    List<dynamic> times,
  ) {
    return DailyPrayerTimes(
      date: date,
      fajr: times[0] as String,
      sunrise: times[1] as String,
      dhuhr: times[2] as String,
      asr: times[3] as String,
      maghrib: times[4] as String,
      isha: times[5] as String,
    );
  }

  String timeFor(TimingType type) {
    switch (type) {
      case TimingType.fajr:
        return fajr;
      case TimingType.sunrise:
        return sunrise;
      case TimingType.dhuhr:
        return dhuhr;
      case TimingType.asr:
        return asr;
      case TimingType.maghrib:
        return maghrib;
      case TimingType.isha:
        return isha;
    }
  }

  DateTime dateTimeFor(TimingType type) {
    final timeStr = timeFor(type);
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Returns the next prayer after [now], or null if all prayers have passed.
  ({TimingType type, DateTime time})? nextPrayer(DateTime now) {
    for (final type in TimingType.prayers) {
      final dt = dateTimeFor(type);
      if (dt.isAfter(now)) {
        return (type: type, time: dt);
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory DailyPrayerTimes.fromJson(Map<String, dynamic> json) {
    return DailyPrayerTimes(
      date: DateFormat('yyyy-MM-dd').parse(json['date'] as String),
      fajr: json['fajr'] as String,
      sunrise: json['sunrise'] as String,
      dhuhr: json['dhuhr'] as String,
      asr: json['asr'] as String,
      maghrib: json['maghrib'] as String,
      isha: json['isha'] as String,
    );
  }

  /// Generate mock prayer times starting [startMinutes] from now,
  /// each spaced [intervalMinutes] apart. For testing athan alerts.
  factory DailyPrayerTimes.mock({
    DateTime? forDate,
    int startMinutes = 1,
    int intervalMinutes = 2,
  }) {
    final day = forDate ?? DateTime.now();
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute + startMinutes + 1);
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final fajr = base;
    final sunrise = base.add(Duration(minutes: intervalMinutes));
    final dhuhr = base.add(Duration(minutes: intervalMinutes * 2));
    final asr = base.add(Duration(minutes: intervalMinutes * 3));
    final maghrib = base.add(Duration(minutes: intervalMinutes * 4));
    final isha = base.add(Duration(minutes: intervalMinutes * 5));

    return DailyPrayerTimes(
      date: day,
      fajr: fmt(fajr),
      sunrise: fmt(sunrise),
      dhuhr: fmt(dhuhr),
      asr: fmt(asr),
      maghrib: fmt(maghrib),
      isha: fmt(isha),
    );
  }
}
