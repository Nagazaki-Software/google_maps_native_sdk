import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'google_maps_native_sdk_platform_interface.dart';

/// A web implementation of the GoogleMapsNativeSdkPlatform of the GoogleMapsNativeSdk plugin.
class GoogleMapsNativeSdkWeb extends GoogleMapsNativeSdkPlatform {
  /// Constructs a GoogleMapsNativeSdkWeb
  GoogleMapsNativeSdkWeb();

  static void registerWith(Registrar registrar) {
    GoogleMapsNativeSdkPlatform.instance = GoogleMapsNativeSdkWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    // Avoid dart:html to keep analyzer clean and dependencies minimal.
    return 'web';
  }
}
