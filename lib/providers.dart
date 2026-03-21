import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/hive_storage.dart';
import 'data/mawaqit_client.dart';
import 'data/prayer_repository.dart';
import 'models/mosque_info.dart';
import 'models/prayer_times.dart';
import 'models/timing_type.dart';
import 'services/athan_service.dart';
import 'services/refresh_service.dart';
import 'services/wakelock_service.dart';

// --- Core singletons ---

final hiveStorageProvider = Provider<HiveStorage>((ref) {
  throw UnimplementedError('Must be overridden at app startup');
});

final mawaqitClientProvider = Provider<MawaqitClient>((ref) {
  final client = MawaqitClient();
  ref.onDispose(client.dispose);
  return client;
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final repo = PrayerRepository(
    client: ref.watch(mawaqitClientProvider),
    storage: ref.watch(hiveStorageProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final wakelockServiceProvider = Provider<WakelockService>((ref) {
  final service = WakelockService(storage: ref.watch(hiveStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});

final athanServiceProvider = Provider<AthanService>((ref) {
  final service = AthanService();
  ref.onDispose(service.dispose);
  return service;
});

final refreshServiceProvider = Provider<RefreshService>((ref) {
  final service = RefreshService(repository: ref.watch(prayerRepositoryProvider));
  ref.onDispose(service.stop);
  return service;
});

// --- Test mode ---

class TestModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final testModeProvider = NotifierProvider<TestModeNotifier, bool>(
  TestModeNotifier.new,
);

// --- Clock ---

class ClockNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = DateTime.now();
    });
    ref.onDispose(() => _timer?.cancel());
    return DateTime.now();
  }
}

final clockProvider = NotifierProvider<ClockNotifier, DateTime>(
  ClockNotifier.new,
);

// --- Mock times ---

class MockTimesNotifier extends Notifier<({DailyPrayerTimes today, DailyPrayerTimes tomorrow})> {
  @override
  ({DailyPrayerTimes today, DailyPrayerTimes tomorrow}) build() => _generate();

  void regenerate() => state = _generate();

  static ({DailyPrayerTimes today, DailyPrayerTimes tomorrow}) _generate() {
    final now = DateTime.now();
    final tmrw = now.add(const Duration(days: 1));
    return (
      today: DailyPrayerTimes.mock(),
      tomorrow: DailyPrayerTimes.mock(forDate: tmrw),
    );
  }
}

final mockTimesProvider =
    NotifierProvider<MockTimesNotifier, ({DailyPrayerTimes today, DailyPrayerTimes tomorrow})>(
  MockTimesNotifier.new,
);

/// Today's prayer times - uses mock times when test mode is on.
final todayTimesProvider = Provider<DailyPrayerTimes?>((ref) {
  final testMode = ref.watch(testModeProvider);
  if (testMode) {
    return ref.watch(mockTimesProvider).today;
  }
  final now = ref.watch(clockProvider);
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getTimesForDate(now);
});

/// Tomorrow's prayer times.
final tomorrowTimesProvider = Provider<DailyPrayerTimes?>((ref) {
  final testMode = ref.watch(testModeProvider);
  if (testMode) {
    return ref.watch(mockTimesProvider).tomorrow;
  }
  ref.watch(clockProvider);
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.tomorrowTimes;
});

/// Next prayer info with [isToday] flag for UI highlighting.
final nextPrayerProvider =
    Provider<({TimingType type, DateTime time, Duration remaining, bool isToday})?>((ref) {
  final now = ref.watch(clockProvider);
  final today = ref.watch(todayTimesProvider);
  if (today == null) return null;

  final next = today.nextPrayer(now);
  if (next != null) {
    return (
      type: next.type,
      time: next.time,
      remaining: next.time.difference(now),
      isToday: true,
    );
  }

  final tomorrow = ref.watch(tomorrowTimesProvider);
  if (tomorrow != null) {
    final fajrTime = tomorrow.dateTimeFor(TimingType.fajr);
    return (
      type: TimingType.fajr,
      time: fajrTime,
      remaining: fajrTime.difference(now),
      isToday: false,
    );
  }
  return null;
});

/// Countdown string for next prayer.
final countdownStringProvider = Provider<String>((ref) {
  final next = ref.watch(nextPrayerProvider);
  if (next == null) return '--:--';
  final remaining = next.remaining;
  if (remaining.isNegative) return '--:--';
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  final seconds = remaining.inSeconds % 60;
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
});

// --- Athan monitoring (driven by clock tick) ---

final athanMonitorProvider = Provider<void>((ref) {
  ref.watch(clockProvider);
  final times = ref.watch(todayTimesProvider);
  final storage = ref.watch(hiveStorageProvider);
  final athan = ref.watch(athanServiceProvider);

  athan.enabledPrayers = storage.athanEnabledPrayers
      .map((n) => TimingType.values.firstWhere((t) => t.name == n,
          orElse: () => TimingType.fajr))
      .where((t) => TimingType.prayers.contains(t))
      .toSet();

  athan.updateTimes(times);
  athan.check();
});

// --- Auto brightness ---

final autoBrightnessProvider = Provider<void>((ref) {
  ref.watch(clockProvider);
  final repo = ref.watch(prayerRepositoryProvider);
  final times = repo.getTimesForDate(DateTime.now());
  if (times == null) return;

  final wakelock = ref.watch(wakelockServiceProvider);
  wakelock.adjustBrightness(times);
});

// --- Mosque search ---

class MosqueSearchNotifier extends Notifier<AsyncValue<List<MosqueInfo>>> {
  Timer? _debounce;

  @override
  AsyncValue<List<MosqueInfo>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncValue.data([]);
  }

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      state = const AsyncValue.data([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncValue.loading();
      try {
        final client = ref.read(mawaqitClientProvider);
        final results = await client.searchMosques(query);
        state = AsyncValue.data(results);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    });
  }
}

final mosqueSearchProvider =
    NotifierProvider<MosqueSearchNotifier, AsyncValue<List<MosqueInfo>>>(
  MosqueSearchNotifier.new,
);
