import 'package:flutter/services.dart';

/// Stops the currently playing native adhan from the Flutter UI.
///
/// The native alarm/service remains responsible for playback; this channel
/// only sends the stop command. Keeping the command on the existing native
/// alarm channel avoids introducing a second Android integration path.
class AdhanPlaybackController {
  static const MethodChannel _channel =
      MethodChannel('aqim/pre_prayer_alarm');

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopAdhanPlayback');
    } on PlatformException {
      // No active native playback is also a valid state for the UI.
    }
  }
}
