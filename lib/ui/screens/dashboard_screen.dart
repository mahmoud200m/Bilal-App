import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/timing_type.dart';
import '../../providers.dart';
import '../overlays/settings_overlay.dart';
import '../widgets/clock_widget.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/prayer_list_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onChangeMosque;

  const DashboardScreen({super.key, required this.onChangeMosque});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TimingType? _athanPlaying;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final wakelock = ref.read(wakelockServiceProvider);
    await wakelock.enableWakelock();

    final refresh = ref.read(refreshServiceProvider);
    refresh.start();

    final athan = ref.read(athanServiceProvider);
    athan.onAthanTriggered = _onAthan;
    athan.onAthanComplete = _onAthanComplete;
  }

  void _onAthan(TimingType prayer) {
    setState(() => _athanPlaying = prayer);
  }

  void _onAthanComplete() {
    if (mounted && _athanPlaying != null) {
      setState(() => _athanPlaying = null);
    }
  }

  @override
  void dispose() {
    final athan = ref.read(athanServiceProvider);
    athan.onAthanTriggered = null;
    athan.onAthanComplete = null;
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SettingsOverlay(
        onChangeMosque: () {
          Navigator.of(context).pop();
          widget.onChangeMosque();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(prayerRepositoryProvider);
    final mosqueName = repo.mosqueInfo?.name ?? '';
    final isTestMode = ref.watch(testModeProvider);

    // Athan monitoring (driven by clock tick)
    ref.watch(athanMonitorProvider);

    // Reactive brightness adjustment (day/night)
    ref.watch(autoBrightnessProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Clock + Countdown
                  Expanded(
                    flex: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ClockWidget(),
                          const SizedBox(height: 40),
                          const CountdownWidget(),
                          const SizedBox(height: 16),
                          Text(
                            mosqueName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: Prayer times list
                  Expanded(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width =
                            constraints.maxWidth.clamp(0.0, 500.0);
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: width,
                            child: const PrayerListWidget(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Settings button — top-left
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white.withOpacity(0.3),
                size: 28,
              ),
              tooltip: 'Settings',
              onPressed: _openSettings,
            ),
          ),

          // Test mode badge — top-right
          if (isTestMode)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Text(
                  'TEST MODE',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Athan overlay
          if (_athanPlaying != null) _buildAthanOverlay(),
        ],
      ),
    );
  }

  Widget _buildAthanOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          ref.read(athanServiceProvider).stopAthan();
          setState(() => _athanPlaying = null);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mosque,
                  color: Colors.tealAccent,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  _athanPlaying!.arabicName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'It\'s time for ${_athanPlaying!.displayName}',
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Tap to dismiss',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
