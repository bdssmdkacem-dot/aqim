import 'package:flutter/services.dart';

/// Handles Android battery/background restrictions so scheduled prayer
/// reminders are less likely to be delayed by Doze or OEM restrictions.
///
/// The package-specific battery optimization request is implemented through
/// a small native MethodChannel. This avoids the third-party dialog flow that
/// can remain visually stuck on some Honor/MagicOS devices.
class BatteryService {
  static const MethodChannel _channel = MethodChannel('aqim/battery');

  static Future<bool> isFullyExempted() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's native package-specific battery optimization dialog.
  ///
  /// Do not assume that opening Settings granted the permission. The caller
  /// re-checks [isFullyExempted] after the app resumes.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } catch (_) {
      await openBatterySettings();
    }
  }

  /// Same native request used by the main battery permission button.
  static Future<void> requestNativeExemption() async {
    await openSettings();
  }

  /// Opens the standard Android battery optimization list.
  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } catch (_) {
      // Nothing else to do if the OEM does not expose this settings screen.
    }
  }

  /// Opens manufacturer-specific instructions when available.
  ///
  /// Kept separate from the package-specific exemption because OEM settings
  /// such as Auto-start are additional restrictions on Honor/MagicOS.
  static Future<void> openManufacturerSettings() async {
    await openBatterySettings();
  }

  /// Opens the OEM auto-start/battery settings screen when available.
  static Future<void> openAutoStartSettings() async {
    await openBatterySettings();
  }
}
