part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Callback invoked when a marker is tapped.
typedef MarkerTapCallback = void Function(String markerId);

/// Controller that drives the native map view via a MethodChannel.
class GoogleMapController {
  GoogleMapController._(this.viewId)
      : _channel = MethodChannel('google_maps_native_sdk/$viewId');

  // Web host bridge (null on Android/iOS)
  WebMapHost? _web;

  // Web-only constructor
  GoogleMapController.web(WebMapHost host)
      : viewId = -1,
        _channel = const MethodChannel('google_maps_native_sdk/web'),
        _web = host;

  /// The platform view id associated with this map instance.
  final int viewId;
  final MethodChannel _channel;

  final StreamController<String> _markerTapController =
      StreamController<String>.broadcast();
  final Completer<void> _mapLoadedCompleter = Completer<void>();

  /// Stream of marker tap events (emits the marker id).
  Stream<String> get onMarkerTap => _markerTapController.stream;
  Future<void> get onMapLoaded => _mapLoadedCompleter.future;

  void _bindCallbacks() {
    if (_web != null) return; // handled by web host
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'event#onMarkerTap':
          final id = call.arguments as String?;
          if (id != null) _markerTapController.add(id);
          break;
        case 'event#onMapLoaded':
          if (!_mapLoadedCompleter.isCompleted) {
            _mapLoadedCompleter.complete();
          }
          break;
      }
    });
  }

  /// Enables/disables clustering (Android/iOS). Should be enabled before adding many markers.
  Future<void> setClusteringEnabled(bool enabled) async {
    if (_web != null) return; // not supported on web
    await _channel.invokeMethod('map#setClusteringEnabled', enabled);
  }

  /// Enables or disables indoor maps (iOS/Android).
  Future<void> setIndoorEnabled(bool enabled) async {
    if (_web != null) return; // not supported on web
    await _channel.invokeMethod('map#setIndoorEnabled', enabled);
  }

  /// Android UI: toggles indoor level picker UI control.
  Future<void> setIndoorLevelPickerEnabled(bool enabled) async {
    if (_web != null) return;
    await _channel.invokeMethod('map#setIndoorLevelPickerEnabled', enabled);
  }

  /// Cloud styling: set Map ID (iOS supported at runtime; Android requires at creation and may be ignored).
  Future<void> setMapId(String mapId) async {
    if (_web != null) return; // not supported on web
    await _channel.invokeMethod('map#setMapId', mapId);
  }

  /// Heatmap overlay: sets/updates the heatmap points. Empty list clears.
  Future<void> setHeatmap(List<LatLng> points, {int? radius, double? opacity}) async {
    if (_web != null) return; // not supported on web
    await _channel.invokeMethod('heatmap#set', {
      'points': points.map((e) => e.toMap()).toList(growable: false),
      if (radius != null) 'radius': radius,
      if (opacity != null) 'opacity': opacity,
    });
  }

  /// Removes any active heatmap overlay.
  Future<void> clearHeatmap() async {
    if (_web != null) return;
    await _channel.invokeMethod('heatmap#clear');
  }

  /// Adds a tile overlay from a URL template. Template may contain {z},{x},{y}.
  Future<void> addTileOverlay(
    String id,
    String urlTemplate, {
    int tileSize = 256,
    double opacity = 1.0,
    double zIndex = 0,
  }) async {
    if (_web != null) return; // not supported on web
    await _channel.invokeMethod('tiles#add', {
      'id': id,
      'template': urlTemplate,
      'tileSize': tileSize,
      'opacity': opacity,
      'zIndex': zIndex,
    });
  }

  Future<void> removeTileOverlay(String id) async {
    if (_web != null) return;
    await _channel.invokeMethod('tiles#remove', id);
  }

  Future<void> clearTileOverlays() async {
    if (_web != null) return;
    await _channel.invokeMethod('tiles#clear');
  }

  // Called by the web host to propagate events
  void handleWebMarkerTap(String markerId) {
    _markerTapController.add(markerId);
  }

  void handleWebMapLoaded() {
    if (!_mapLoadedCompleter.isCompleted) {
      _mapLoadedCompleter.complete();
    }
  }

  /// Moves the camera to [target] and optionally sets [zoom], [tilt] and [bearing].
  Future<void> moveCamera(
    LatLng target, {
    double? zoom,
    double? tilt,
    double? bearing,
  }) async {
    if (_web != null) {
      await _web!.moveCamera(target, zoom: zoom, tilt: tilt, bearing: bearing);
    } else {
      await _channel.invokeMethod('map#moveCamera', {
        'target': target.toMap(),
        if (zoom != null) 'zoom': zoom,
        if (tilt != null) 'tilt': tilt,
        if (bearing != null) 'bearing': bearing,
      });
    }
  }

  /// Animates the camera to fit [northeast] and [southwest] with [padding].
  Future<void> animateToBounds(
    LatLng northeast,
    LatLng southwest, {
    double padding = 50,
  }) async {
    if (_web != null) {
      await _web!.animateToBounds(northeast, southwest, padding: padding);
    } else {
      await _channel.invokeMethod('map#animateToBounds', {
        'ne': northeast.toMap(),
        'sw': southwest.toMap(),
        'padding': padding,
      });
    }
  }

  /// Smoothly animates the camera to [target] with optional [zoom], [tilt], [bearing] and [durationMs].
  Future<void> animateCamera(
    LatLng target, {
    double? zoom,
    double? tilt,
    double? bearing,
    int? durationMs,
  }) async {
    if (_web != null) {
      await _web!.animateCamera(target, zoom: zoom, tilt: tilt, bearing: bearing, durationMs: durationMs);
    } else {
      await _channel.invokeMethod('map#animateCamera', {
        'target': target.toMap(),
        if (zoom != null) 'zoom': zoom,
        if (tilt != null) 'tilt': tilt,
        if (bearing != null) 'bearing': bearing,
        if (durationMs != null) 'durationMs': durationMs,
      });
    }
  }

  /// Enables/disables traffic overlay.
  Future<void> setTrafficEnabled(bool enabled) async {
    if (_web != null) {
      await _web!.setTrafficEnabled(enabled);
    } else {
      await _channel.invokeMethod('map#setTrafficEnabled', enabled);
    }
  }

  /// Enables/disables the native my-location layer (requires permissions on Android).
  Future<void> setMyLocationEnabled(bool enabled) async {
    if (_web != null) {
      // no-op on web
      return;
    } else {
      await _channel.invokeMethod('map#setMyLocationEnabled', enabled);
    }
  }

  /// Sets map padding to avoid overlaying UI elements.
  Future<void> setPadding(MapPadding padding) async {
    if (_web != null) {
      await _web!.setPadding(padding);
    } else {
      await _channel.invokeMethod('map#setPadding', padding.toMap());
    }
  }

  /// Applies a raw Google Maps JSON style.
  Future<void> setMapStyle(String? mapStyleJson) async {
    if (_web != null) {
      await _web!.setMapStyle(mapStyleJson);
    } else {
      await _channel.invokeMethod('map#setStyle', mapStyleJson);
    }
  }

  /// Applies a single-color style tint. If [dark] is true, uses darker contrasts.
  Future<void> setMapColor(Color color, {bool dark = false}) async {
    final style = MapStyleBuilder.tinted(color, dark: dark);
    await setMapStyle(style);
  }

  /// Adds a marker with [options]. Re-adding with same id replaces existing.
  Future<void> addMarker(MarkerOptions options) async {
    if (_web != null) {
      await _web!.addMarker(options);
    } else {
      await _channel.invokeMethod('markers#add', options.toMap());
    }
  }

  /// Updates a marker by [id]. You may change [position] and/or [rotation].
  Future<void> updateMarker(
    String id, {
    LatLng? position,
    double? rotation,
  }) async {
    if (_web != null) {
      await _web!.updateMarker(id, position: position, rotation: rotation);
    } else {
      await _channel.invokeMethod('markers#update', {
        'id': id,
        if (position != null) 'position': position.toMap(),
        if (rotation != null) 'rotation': rotation,
      });
    }
  }

  /// Removes a marker by [id].
  Future<void> removeMarker(String id) async {
    if (_web != null) {
      await _web!.removeMarker(id);
    } else {
      await _channel.invokeMethod('markers#remove', id);
    }
  }

  /// Removes all markers.
  Future<void> clearMarkers() async {
    if (_web != null) {
      await _web!.clearMarkers();
    } else {
      await _channel.invokeMethod('markers#clear');
    }
  }

  /// Adds a polyline with [options]. Re-adding with same id replaces existing.
  Future<void> addPolyline(PolylineOptions options) async {
    if (_web != null) {
      await _web!.addPolyline(options);
    } else {
      await _channel.invokeMethod('polylines#add', options.toMap());
    }
  }

  /// Adds a polyline by decoding an encoded polyline string.
  Future<void> addPolylineFromEncoded(
    String id,
    String encoded, {
    Color color = const Color(0xFF1B5E20),
    double width = 6,
  }) async {
    final pts = PolylineCodec.decode(encoded);
    await addPolyline(
      PolylineOptions(id: id, points: pts, color: color, width: width),
    );
  }

  /// Removes a polyline by [id].
  Future<void> removePolyline(String id) async {
    if (_web != null) {
      await _web!.removePolyline(id);
    } else {
      await _channel.invokeMethod('polylines#remove', id);
    }
  }

  /// Removes all polylines.
  Future<void> clearPolylines() async {
    if (_web != null) {
      await _web!.clearPolylines();
    } else {
      await _channel.invokeMethod('polylines#clear');
    }
  }

  /// Updates the points of an existing polyline by [id] without recreating it.
  Future<void> updatePolylinePoints(String id, List<LatLng> points) async {
    if (_web != null) {
      await _web!.updatePolylinePoints(id, points);
    } else {
      await _channel.invokeMethod('polylines#updatePoints', {
        'id': id,
        'points': points.map((e) => e.toMap()).toList(growable: false),
      });
    }
  }

  /// Captures a PNG snapshot of the current map viewport.
  Future<Uint8List?> takeSnapshot() async {
    if (_web != null) {
      return await _web!.takeSnapshot();
    } else {
      final res = await _channel.invokeMethod('map#takeSnapshot');
      if (res is Uint8List) return res;
      return null;
    }
  }

  /// Releases native resources for this map instance.
  Future<void> dispose() async {
    if (_web != null) {
      await _web!.dispose();
    } else {
      await _channel.invokeMethod('map#dispose');
    }
    await _markerTapController.close();
    if (!_mapLoadedCompleter.isCompleted) {
      _mapLoadedCompleter.completeError(StateError('disposed'));
    }
  }
}
