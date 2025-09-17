import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_native_sdk/google_maps_native_sdk.dart';
import 'package:google_maps_native_sdk/google_maps_native_sdk_platform_interface.dart';
import 'package:google_maps_native_sdk/google_maps_native_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGoogleMapsNativeSdkPlatform
    with MockPlatformInterfaceMixin
    implements GoogleMapsNativeSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GoogleMapsNativeSdkPlatform initialPlatform =
      GoogleMapsNativeSdkPlatform.instance;

  test('$MethodChannelGoogleMapsNativeSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGoogleMapsNativeSdk>());
  });

  test('getPlatformVersion', () async {
    GoogleMapsNativeSdk googleMapsNativeSdkPlugin = GoogleMapsNativeSdk();
    MockGoogleMapsNativeSdkPlatform fakePlatform =
        MockGoogleMapsNativeSdkPlatform();
    GoogleMapsNativeSdkPlatform.instance = fakePlatform;

    expect(await googleMapsNativeSdkPlugin.getPlatformVersion(), '42');
  });
}
