import '../models/mosque_info.dart';
import '../models/prayer_times.dart';
import '../models/yearly_calendar.dart';
import 'hive_storage.dart';
import 'mawaqit_client.dart';

class PrayerRepository {
  final MawaqitClient _client;
  final HiveStorage _storage;

  YearlyCalendar? _calendar;
  MosqueInfo? _mosqueInfo;

  PrayerRepository({
    required MawaqitClient client,
    required HiveStorage storage,
  })  : _client = client,
        _storage = storage;

  MosqueInfo? get mosqueInfo => _mosqueInfo;
  YearlyCalendar? get calendar => _calendar;
  bool get hasData => _calendar != null;
  bool get isSetUp => _storage.onboardingDone && hasData;

  /// Load cached data from Hive on app start.
  Future<void> loadFromCache() async {
    _calendar = _storage.loadCalendar();
    _mosqueInfo = _storage.loadMosqueInfo();
  }

  /// Full onboarding: fetch mosque data + yearly calendar and cache.
  Future<void> setupMosque(String mosqueSlug) async {
    final result = await _client.fetchMosqueFull(mosqueSlug);
    _mosqueInfo = result.info;
    _calendar = result.calendar;

    await _storage.saveMosqueInfo(result.info);
    await _storage.saveCalendar(result.calendar);
    await _storage.setOnboardingDone(true);
  }

  /// Re-fetch calendar if stale (weekly).
  Future<bool> refreshIfNeeded() async {
    if (!_storage.needsRefresh) return false;
    final slug = _storage.selectedSlug;
    if (slug == null) return false;
    try {
      final calendar = await _client.fetchYearlyCalendar(slug);
      _calendar = calendar;
      await _storage.saveCalendar(calendar);
      return true;
    } catch (_) {
      // Refresh failed, cached data still works.
      return false;
    }
  }

  /// Force refresh now.
  Future<void> forceRefresh() async {
    final slug = _storage.selectedSlug;
    if (slug == null) return;
    final calendar = await _client.fetchYearlyCalendar(slug);
    _calendar = calendar;
    await _storage.saveCalendar(calendar);
  }

  /// Get today's prayer times.
  DailyPrayerTimes? get todayTimes => _calendar?.today;

  /// Get tomorrow's prayer times.
  DailyPrayerTimes? get tomorrowTimes => _calendar?.tomorrow;

  /// Get prayer times for any date.
  DailyPrayerTimes? getTimesForDate(DateTime date) => _calendar?.getDay(date);

  /// Search mosques (delegates to client).
  Future<List<MosqueInfo>> searchMosques(String query) {
    return _client.searchMosques(query);
  }

  /// Change to a different mosque.
  Future<void> changeMosque(String mosqueSlug) async {
    await setupMosque(mosqueSlug);
  }

  void dispose() {
    // Client lifecycle is managed by its own provider.
  }
}
