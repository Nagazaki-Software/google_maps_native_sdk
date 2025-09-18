/// Native Google Maps plugin for Flutter/FlutterFlow.
///
/// Provides a `GoogleMapView` widget backed by platform views (Android/iOS)
/// and a `GoogleMapController` for interacting with the map: markers,
/// polylines, camera movement, styling, snapshots and events.
library google_maps_native_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'google_maps_native_sdk_platform_interface.dart';
import 'src/web_host_types.dart';
import 'src/web_map_stub.dart' if (dart.library.html) 'src/web_map_impl.dart' as webmap;

part 'src/types.dart';
part 'src/controller.dart';
part 'src/view.dart';
part 'src/style.dart';
part 'src/navigation.dart';
part 'src/static_map.dart';
part 'src/routes.dart';
part 'src/flutterflow_helpers.dart';
part 'src/nav_banner.dart';

/// Convenience wrapper exposing package/platform version from the host side.
class GoogleMapsNativeSdk {
  /// Returns the platform version string from the native side (for tests).
  Future<String?> getPlatformVersion() {
    return GoogleMapsNativeSdkPlatform.instance.getPlatformVersion();
  }
}
