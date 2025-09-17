import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'google_maps_native_sdk_platform_interface.dart';

/// An implementation of [GoogleMapsNativeSdkPlatform] that uses method channels.
class MethodChannelGoogleMapsNativeSdk extends GoogleMapsNativeSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('google_maps_native_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
