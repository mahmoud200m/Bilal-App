import 'package:audioplayers/audioplayers.dart';
import '../models/prayer_times.dart';
import '../models/timing_type.dart';

class AthanService {
  final AudioPlayer _player = AudioPlayer();
  DailyPrayerTimes? _todayTimes;
  final Set<TimingType> _playedToday = {};
  void Function(TimingType prayer)? onAthanTriggered;
  void Function()? onAthanComplete;

  static const _athanAsset = 'athan.mp3';
  static const _athanFajrAsset = 'athan_fajr.mp3';

  Set<TimingType> enabledPrayers = TimingType.prayers.toSet();

  bool isEnabled(TimingType prayer) => enabledPrayers.contains(prayer);

  bool _playing = false;
  bool get playing => _playing;

  AthanService() {
    _player.onPlayerComplete.listen((_) {
      _playing = false;
      onAthanComplete?.call();
    });
  }

  void updateTimes(DailyPrayerTimes? times) {
    final newDate = times?.date;
    final oldDate = _todayTimes?.date;
    final dayChanged = newDate?.year != oldDate?.year ||
        newDate?.month != oldDate?.month ||
        newDate?.day != oldDate?.day;
    if (dayChanged) {
      _playedToday.clear();
    }
    _todayTimes = times;
  }

  void check() {
    if (_todayTimes == null) return;
    final now = DateTime.now();

    for (final prayer in TimingType.prayers) {
      if (_playedToday.contains(prayer)) continue;
      if (!enabledPrayers.contains(prayer)) continue;

      final prayerTime = _todayTimes!.dateTimeFor(prayer);
      final diff = now.difference(prayerTime).inSeconds;

      if (diff >= 0 && diff < 30) {
        _playedToday.add(prayer);
        playAthan(prayer: prayer);
        onAthanTriggered?.call(prayer);
        break;
      }
    }
  }

  Future<void> playAthan({TimingType? prayer}) async {
    final asset =
        prayer == TimingType.fajr ? _athanFajrAsset : _athanAsset;
    try {
      await _player.stop();
      _playing = true;
      await _player.play(AssetSource(asset));
    } catch (_) {
      _playing = false;
    }
  }

  Future<void> stopAthan() async {
    _playing = false;
    await _player.stop();
  }

  void dispose() {
    _player.stop();
    _player.dispose();
  }
}
