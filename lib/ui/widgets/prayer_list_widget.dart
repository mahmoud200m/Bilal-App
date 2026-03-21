import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/prayer_times.dart';
import '../../models/timing_type.dart';
import '../../providers.dart';

class PrayerListWidget extends ConsumerWidget {
  const PrayerListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final times = ref.watch(todayTimesProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);
    final tomorrowTimes = ref.watch(tomorrowTimesProvider);

    if (times == null) {
      return const Center(
        child: Text(
          'No prayer times available',
          style: TextStyle(color: Colors.white38, fontSize: 18),
        ),
      );
    }

    final isNextToday = nextPrayer?.isToday ?? false;
    final athanEnabled = ref.watch(hiveStorageProvider).athanEnabledPrayers;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...TimingType.values.map((prayer) {
          final isNext = isNextToday && nextPrayer?.type == prayer;
          final isPassed = !isNext &&
              times.dateTimeFor(prayer).isBefore(DateTime.now());
          final isMuted = prayer != TimingType.sunrise &&
              !athanEnabled.contains(prayer.name);

          return _PrayerRow(
            prayer: prayer,
            time: times.timeFor(prayer),
            isNext: isNext,
            isPassed: isPassed,
            isMuted: isMuted,
          );
        }),
        if (tomorrowTimes != null) ...[
          const SizedBox(height: 12),
          _TomorrowRow(tomorrowTimes: tomorrowTimes),
        ],
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final TimingType prayer;
  final String time;
  final bool isNext;
  final bool isPassed;
  final bool isMuted;

  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.isNext,
    required this.isPassed,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isNext
        ? Colors.tealAccent.withOpacity(0.15)
        : Colors.transparent;

    final textColor = isPassed
        ? Colors.white.withOpacity(0.3)
        : isNext
            ? Colors.tealAccent
            : Colors.white;

    final nameStyle = TextStyle(
      color: textColor,
      fontSize: 28,
      fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
    );

    final timeStyle = TextStyle(
      color: textColor,
      fontSize: 32,
      fontWeight: isNext ? FontWeight.w700 : FontWeight.w300,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final arabicStyle = TextStyle(
      color: textColor.withOpacity(0.6),
      fontSize: 20,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isNext
            ? Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1)
            : null,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          if (isNext)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_right, color: Colors.tealAccent, size: 28),
            ),
          Expanded(
            flex: 3,
            child: Text(prayer.displayName, style: nameStyle),
          ),
          if (isMuted)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.notifications_off,
                  color: Colors.white.withOpacity(0.3), size: 22),
            ),
          Text(prayer.arabicName, style: arabicStyle),
          const SizedBox(width: 24),
          Text(time, style: timeStyle),
        ],
      ),
    );
  }
}

class _TomorrowRow extends StatelessWidget {
  final DailyPrayerTimes tomorrowTimes;

  const _TomorrowRow({required this.tomorrowTimes});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Colors.white24,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    const timeStyle = TextStyle(
      color: Colors.white38,
      fontSize: 14,
      fontWeight: FontWeight.w300,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Tomorrow',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          for (final prayer in TimingType.values) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(prayer.displayName.substring(0, 3), style: labelStyle),
                const SizedBox(height: 2),
                Text(tomorrowTimes.timeFor(prayer), style: timeStyle),
              ],
            ),
            if (prayer != TimingType.isha) const SizedBox(width: 20),
          ],
        ],
      ),
    );
  }
}
