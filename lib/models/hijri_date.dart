/// Hijri date computed using the tabular/arithmetic Islamic calendar,
/// matching Mawaqit's JavaScript implementation exactly.
class HijriDate {
  final int day;
  final int month; // 1-based (1=Muharram, 9=Ramadan, etc.)
  final int year;

  const HijriDate({required this.day, required this.month, required this.year});

  static const _monthNames = [
    'Muharram',
    'Safar',
    'Rabīʿ al-Awwal',
    'Rabīʿ ath-Thānī',
    'Jumādá al-Ūlá',
    'Jumādá al-Ākhirah',
    'Rajab',
    'Shaʿbān',
    'Ramaḍān',
    'Shawwāl',
    'Dhū al-Qaʿdah',
    'Dhū al-Ḥijjah',
  ];

  String get monthName => _monthNames[month - 1];

  /// Compute the Hijri date for [date], applying [adjustment] days offset
  /// (from Mawaqit's confData.hijriAdjustment).
  factory HijriDate.fromGregorian(DateTime date, {int adjustment = 0}) {
    final adjusted = adjustment != 0
        ? date.add(Duration(days: adjustment))
        : date;

    final r = adjusted.day;
    final o = adjusted.month; // 1-based
    final s = adjusted.year;

    var u = o;
    var d = s;
    if (u < 3) {
      d -= 1;
      u += 12;
    }

    final h = d ~/ 100;
    var f = 2 - h + (h ~/ 4);
    if (d < 1583) f = 0;
    if (d == 1582) {
      if (u > 10) f = -10;
      if (u == 10) {
        f = 0;
        if (r > 4) f = -10;
      }
    }

    // Julian Day Number
    final c = (365.25 * (d + 4716)).floor() +
        (30.6001 * (u + 1)).floor() +
        r +
        f -
        1524;

    // Tabular Islamic calendar from JDN
    const y = 10631.0 / 30;
    const w = 0.1335;
    var p = c - 1948084;
    final cycles = p ~/ 10631;
    p -= 10631 * cycles;
    final yearInCycle = ((p - w) / y).floor();
    final hijriYear = 30 * cycles + yearInCycle;
    p -= (yearInCycle * y + w).floor();

    var hijriMonth = ((p + 28.5001) / 29.5).floor();
    if (hijriMonth == 13) hijriMonth = 12;
    final hijriDay = p - (29.5001 * hijriMonth - 29).floor();

    return HijriDate(day: hijriDay, month: hijriMonth, year: hijriYear);
  }

  @override
  String toString() => '$day $monthName $year AH';
}
