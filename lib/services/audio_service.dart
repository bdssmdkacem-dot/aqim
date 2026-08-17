import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Plays bundled local audio for individual adhkar.
/// Missing optional recordings are handled without crashing the screen.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playAsset(BuildContext context, String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('التسجيل الصوتي غير متوفر لهذا الذكر حاليًا'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> stop() => _player.stop();
}
