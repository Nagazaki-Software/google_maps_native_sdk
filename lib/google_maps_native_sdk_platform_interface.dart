import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'google_maps_native_sdk_method_channel.dart';

/// Platform interface for `google_maps_native_sdk`.
///
/// Allows alternative implementations to provide the platform version and
/// other platform-specific functionality. The default uses a method channel.
abstract class GoogleMapsNativeSdkPlatform extends PlatformInterface {
  /// Constructs a GoogleMapsNativeSdkPlatform.
  GoogleMapsNativeSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static GoogleMapsNativeSdkPlatform _instance =
      MethodChannelGoogleMapsNativeSdk();

  /// The default instance of [GoogleMapsNativeSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelGoogleMapsNativeSdk].
  static GoogleMapsNativeSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GoogleMapsNativeSdkPlatform] when
  /// they register themselves.
  static set instance(GoogleMapsNativeSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the platform version string from the host platform.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
