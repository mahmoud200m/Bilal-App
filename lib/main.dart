import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/hive_storage.dart';
import 'providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure audio session so athan plays through speaker,
  // even when the iOS silent switch is on.
  final globalPlayer = AudioPlayer();
  await globalPlayer.setAudioContext(AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {},
    ),
    android: AudioContextAndroid(
      usageType: AndroidUsageType.media,
      contentType: AndroidContentType.music,
    ),
  ));
  await globalPlayer.dispose();

  final storage = HiveStorage();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        hiveStorageProvider.overrideWithValue(storage),
      ],
      child: const BilalApp(),
    ),
  );
}
