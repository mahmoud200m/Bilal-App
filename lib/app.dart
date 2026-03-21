import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/onboarding_screen.dart';

class BilalApp extends ConsumerStatefulWidget {
  const BilalApp({super.key});

  @override
  ConsumerState<BilalApp> createState() => _BilalAppState();
}

class _BilalAppState extends ConsumerState<BilalApp> {
  bool _isReady = false;
  bool _needsOnboarding = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Immersive fullscreen mode
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final repo = ref.read(prayerRepositoryProvider);
    await repo.loadFromCache();

    if (!mounted) return;
    setState(() {
      _needsOnboarding = !repo.isSetUp;
      _isReady = true;
    });
  }

  void _onOnboardingComplete() {
    setState(() {
      _needsOnboarding = false;
    });
  }

  void _onChangeMosque() {
    setState(() {
      _needsOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bilal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    if (_needsOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    return DashboardScreen(onChangeMosque: _onChangeMosque);
  }
}
