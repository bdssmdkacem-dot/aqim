import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// يشغّل ملفات الصوت التي سيسجّلها المستخدم لاحقًا ويضعها ضمن
/// assets/audio/before/ و assets/audio/after/ (راجع README).
/// إن لم يُضَف الملف بعد، يفشل التشغيل بهدوء ويظهر تنبيه بسيط بدل الانهيار.
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
            content: Text('لم يُضَف التسجيل الصوتي لهذا الذكر بعد'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> stop() => _player.stop();
}
