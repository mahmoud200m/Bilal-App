import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/timing_type.dart';
import '../../providers.dart';

class SettingsOverlay extends ConsumerStatefulWidget {
  final VoidCallback onChangeMosque;

  const SettingsOverlay({super.key, required this.onChangeMosque});

  @override
  ConsumerState<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends ConsumerState<SettingsOverlay> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(hiveStorageProvider);
    final repo = ref.watch(prayerRepositoryProvider);
    final mosqueName = repo.mosqueInfo?.name ?? 'Unknown';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Current mosque
          _SettingsTile(
            icon: Icons.mosque,
            title: 'Mosque',
            subtitle: mosqueName,
            trailing: TextButton(
              onPressed: widget.onChangeMosque,
              child: const Text(
                'Change',
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ),
          const Divider(color: Colors.white12),

          // Night brightness
          _SettingsTile(
            icon: Icons.brightness_2,
            title: 'Night Brightness',
            subtitle: '${(storage.brightnessNight * 100).round()}%',
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: storage.brightnessNight,
                min: 0.01,
                max: 0.3,
                activeColor: Colors.tealAccent,
                onChanged: (v) async {
                  await storage.setBrightnessNight(v);
                  final repo = ref.read(prayerRepositoryProvider);
                  final times = repo.getTimesForDate(DateTime.now());
                  await ref.read(wakelockServiceProvider).adjustBrightness(times);
                  setState(() {});
                },
              ),
            ),
          ),
          const Divider(color: Colors.white12),

          // Day brightness
          _SettingsTile(
            icon: Icons.brightness_high,
            title: 'Day Brightness',
            subtitle: '${(storage.brightnessDay * 100).round()}%',
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: storage.brightnessDay,
                min: 0.1,
                max: 1.0,
                activeColor: Colors.tealAccent,
                onChanged: (v) async {
                  await storage.setBrightnessDay(v);
                  final repo = ref.read(prayerRepositoryProvider);
                  final times = repo.getTimesForDate(DateTime.now());
                  await ref.read(wakelockServiceProvider).adjustBrightness(times);
                  setState(() {});
                },
              ),
            ),
          ),
          const Divider(color: Colors.white12),

          // Per-prayer athan toggles
          _SettingsTile(
            icon: Icons.volume_up,
            title: 'Athan Sound',
            subtitle: 'Toggle athan for each prayer',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: TimingType.prayers.map((prayer) {
                final enabled = storage.athanEnabledPrayers.contains(prayer.name);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () async {
                      final current = storage.athanEnabledPrayers;
                      if (enabled) {
                        current.remove(prayer.name);
                      } else {
                        current.add(prayer.name);
                      }
                      await storage.setAthanEnabledPrayers(current);
                      setState(() {});
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          enabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: enabled
                              ? Colors.tealAccent
                              : Colors.white24,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prayer.displayName.substring(0, 3),
                          style: TextStyle(
                            color: enabled
                                ? Colors.tealAccent
                                : Colors.white24,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white12),

          // Test athan button
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Test Athan',
            subtitle: ref.watch(athanServiceProvider).playing
                ? 'Playing athan...'
                : 'Play athan sound now',
            trailing: IconButton(
              icon: Icon(
                ref.watch(athanServiceProvider).playing
                    ? Icons.stop
                    : Icons.play_arrow,
                color: Colors.tealAccent,
              ),
              onPressed: () {
                final athan = ref.read(athanServiceProvider);
                if (athan.playing) {
                  athan.stopAthan();
                  setState(() {});
                } else {
                  final saved = athan.onAthanComplete;
                  athan.onAthanComplete = () {
                    athan.onAthanComplete = saved;
                    if (mounted) setState(() {});
                  };
                  athan.playAthan();
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(color: Colors.white12),

          // Test mode
          _SettingsTile(
            icon: Icons.bug_report,
            title: 'Test Mode',
            subtitle: 'Mock prayers every 2 min starting in ~1 min',
            trailing: Switch(
              value: ref.watch(testModeProvider),
              activeColor: Colors.orange,
              onChanged: (v) {
                if (v) {
                  ref.read(mockTimesProvider.notifier).regenerate();
                }
                ref.read(testModeProvider.notifier).toggle(v);
              },
            ),
          ),
          const Divider(color: Colors.white12),

          // Refresh data
          _SettingsTile(
            icon: Icons.refresh,
            title: 'Refresh Prayer Times',
            subtitle: _refreshing
                ? 'Refreshing...'
                : 'Last: ${_formatLastRefresh(storage.lastRefresh)}',
            trailing: _refreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.tealAccent,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync, color: Colors.tealAccent),
                    onPressed: () async {
                      setState(() => _refreshing = true);
                      try {
                        await repo.forceRefresh();
                      } catch (_) {}
                      if (mounted) setState(() => _refreshing = false);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatLastRefresh(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
