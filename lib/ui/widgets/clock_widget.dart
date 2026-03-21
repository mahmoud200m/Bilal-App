import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/hijri_date.dart';
import '../../providers.dart';

class ClockWidget extends ConsumerWidget {
  const ClockWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    final repo = ref.watch(prayerRepositoryProvider);
    final adjustment = repo.mosqueInfo?.hijriAdjustment ?? 0;
    final hijri = HijriDate.fromGregorian(now, adjustment: adjustment);
    final hijriStr = hijri.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 96,
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          dateStr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hijriStr,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
