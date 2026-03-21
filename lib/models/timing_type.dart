enum TimingType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  String get displayName {
    switch (this) {
      case TimingType.fajr:
        return 'Fajr';
      case TimingType.sunrise:
        return 'Sunrise';
      case TimingType.dhuhr:
        return 'Dhuhr';
      case TimingType.asr:
        return 'Asr';
      case TimingType.maghrib:
        return 'Maghrib';
      case TimingType.isha:
        return 'Isha';
    }
  }

  String get arabicName {
    switch (this) {
      case TimingType.fajr:
        return 'الفجر';
      case TimingType.sunrise:
        return 'الشروق';
      case TimingType.dhuhr:
        return 'الظهر';
      case TimingType.asr:
        return 'العصر';
      case TimingType.maghrib:
        return 'المغرب';
      case TimingType.isha:
        return 'العشاء';
    }
  }

  /// The 5 actual prayers (excluding sunrise).
  static List<TimingType> get prayers =>
      [fajr, dhuhr, asr, maghrib, isha];

}
