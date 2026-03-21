import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../data/hive_storage.dart';
import '../models/prayer_times.dart';
import '../models/timing_type.dart';

class WakelockService {
  final HiveStorage _storage;
  double? _lastBrightness;

  WakelockService({required HiveStorage storage}) : _storage = storage;

  Future<void> enableWakelock() async {
    await WakelockPlus.enable();
  }

  Future<void> disableWakelock() async {
    await WakelockPlus.disable();
  }

  /// Adjust brightness based on current time relative to prayer times.
  /// Dim at night (between Isha and Fajr), brighter during the day.
  Future<void> adjustBrightness(DailyPrayerTimes? times) async {
    if (times == null) return;

    final now = DateTime.now();
    final fajrTime = times.dateTimeFor(TimingType.fajr);
    final ishaTime = times.dateTimeFor(TimingType.isha);

    final isNight = now.isAfter(ishaTime) || now.isBefore(fajrTime);

    final targetBrightness =
        isNight ? _storage.brightnessNight : _storage.brightnessDay;

    if (targetBrightness == _lastBrightness) return;
    _lastBrightness = targetBrightness;

    try {
      await ScreenBrightness().setScreenBrightness(targetBrightness);
    } catch (_) {
      // Brightness control might not be available on all devices.
    }
  }

  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (_) {}
  }

  void dispose() {
    resetBrightness();
    disableWakelock();
  }
}
