import 'package:flutter/services.dart';

/// Controls the currently playing adhan from the Flutter UI.
///
/// The Android side is responsible for the actual alarm playback. This
/// channel only sends a stop command to the native receiver/service so the
/// in-app Stop button does not depend on the notification action.
class AdhanPlaybackController {
  static const MethodChannel _channel =
      MethodChannel('com.aqim.app/adhan_playback');

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopAdhan');
    } on PlatformException {
      // Keep the UI resilient if there is no active native playback.
    }
  }
}
