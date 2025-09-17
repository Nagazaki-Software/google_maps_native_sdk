/// Native Google Maps plugin for Flutter/FlutterFlow.
///
/// Provides a `GoogleMapView` widget backed by platform views (Android/iOS)
/// and a `GoogleMapController` for interacting with the map: markers,
/// polylines, camera movement, styling, snapshots and events.
library google_maps_native_sdk;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'google_maps_native_sdk_platform_interface.dart';

part 'src/types.dart';
part 'src/controller.dart';
part 'src/view.dart';
part 'src/style.dart';

/// Convenience wrapper exposing package/platform version from the host side.
class GoogleMapsNativeSdk {
  /// Returns the platform version string from the native side (for tests).
  Future<String?> getPlatformVersion() {
    return GoogleMapsNativeSdkPlatform.instance.getPlatformVersion();
  }
}
