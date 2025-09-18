import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'google_maps_native_sdk_platform_interface.dart';

/// Default platform implementation using a `MethodChannel`.
class MethodChannelGoogleMapsNativeSdk extends GoogleMapsNativeSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('google_maps_native_sdk');

  /// Invokes the native `getPlatformVersion` method and returns its value.
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
