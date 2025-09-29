part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Minimal audio focus helper (Android) and iOS ducking via flutter_tts.
/// On Android, uses a small platform channel to request/abandon focus.
class AudioFocus {
  static const MethodChannel _ch = MethodChannel('google_maps_native_sdk/audio');

  static Future<bool> request() async {
    try {
      final res = await _ch.invokeMethod('audio#request');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> abandon() async {
    try {
      await _ch.invokeMethod('audio#abandon');
    } catch (_) {}
  }
}

