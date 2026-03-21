import 'dart:async';
import '../data/prayer_repository.dart';

/// Periodically checks if the cached calendar needs refreshing.
class RefreshService {
  final PrayerRepository _repository;
  Timer? _timer;

  RefreshService({required PrayerRepository repository})
      : _repository = repository;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _tryRefresh(),
    );
    // Also try on startup.
    _tryRefresh();
  }

  Future<void> _tryRefresh() async {
    try {
      await _repository.refreshIfNeeded();
    } catch (_) {
      // Silent failure -- cached data continues to work.
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
