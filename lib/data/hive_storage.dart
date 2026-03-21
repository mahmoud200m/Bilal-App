import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mosque_info.dart';
import '../models/yearly_calendar.dart';

class HiveStorage {
  static const _calendarBox = 'calendar';
  static const _settingsBox = 'settings';

  static const _keyCalendar = 'yearly_calendar';
  static const _keyMosqueInfo = 'mosque_info';
  static const _keyLastRefresh = 'last_refresh';
  static const _keySelectedSlug = 'selected_slug';
  static const _keyBrightnessNight = 'brightness_night';
  static const _keyBrightnessDay = 'brightness_day';
  static const _keyScreenOffBetween = 'screen_off_between';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyAthanEnabled = 'athan_enabled';

  late Box _calendar;
  late Box _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _calendar = await Hive.openBox(_calendarBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // --- Calendar ---

  Future<void> saveCalendar(YearlyCalendar calendar) async {
    await _calendar.put(_keyCalendar, jsonEncode(calendar.toJson()));
    await _calendar.put(_keyLastRefresh, DateTime.now().toIso8601String());
  }

  YearlyCalendar? loadCalendar() {
    final raw = _calendar.get(_keyCalendar) as String?;
    if (raw == null) return null;
    try {
      return YearlyCalendar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  DateTime? get lastRefresh {
    final raw = _calendar.get(_keyLastRefresh) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool get needsRefresh {
    final last = lastRefresh;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= 7;
  }

  // --- Mosque Info ---

  Future<void> saveMosqueInfo(MosqueInfo info) async {
    await _settings.put(_keyMosqueInfo, jsonEncode(info.toJson()));
    await _settings.put(_keySelectedSlug, info.slug);
  }

  MosqueInfo? loadMosqueInfo() {
    final raw = _settings.get(_keyMosqueInfo) as String?;
    if (raw == null) return null;
    try {
      return MosqueInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String? get selectedSlug => _settings.get(_keySelectedSlug) as String?;

  // --- Settings ---

  bool get onboardingDone => _settings.get(_keyOnboardingDone, defaultValue: false) as bool;
  Future<void> setOnboardingDone(bool v) => _settings.put(_keyOnboardingDone, v);

  double get brightnessNight => (_settings.get(_keyBrightnessNight, defaultValue: 0.05) as num).toDouble();
  Future<void> setBrightnessNight(double v) => _settings.put(_keyBrightnessNight, v);

  double get brightnessDay => (_settings.get(_keyBrightnessDay, defaultValue: 0.6) as num).toDouble();
  Future<void> setBrightnessDay(double v) => _settings.put(_keyBrightnessDay, v);

  Set<String> get athanEnabledPrayers {
    final raw = _settings.get(_keyAthanEnabled) as List?;
    if (raw == null) return {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};
    return raw.cast<String>().toSet();
  }

  Future<void> setAthanEnabledPrayers(Set<String> prayers) =>
      _settings.put(_keyAthanEnabled, prayers.toList());

  bool get screenOffBetween => _settings.get(_keyScreenOffBetween, defaultValue: false) as bool;
  Future<void> setScreenOffBetween(bool v) => _settings.put(_keyScreenOffBetween, v);

  Future<void> clearAll() async {
    await _calendar.clear();
    await _settings.clear();
  }
}
