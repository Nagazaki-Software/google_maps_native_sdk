part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Callback invoked when a marker is tapped.
typedef MarkerTapCallback = void Function(String markerId);

/// Controller that drives the native map view via a MethodChannel.
class GoogleMapController {
  GoogleMapController._(this.viewId)
      : _channel = MethodChannel('google_maps_native_sdk/$viewId');

  /// The platform view id associated with this map instance.
  final int viewId;
  final MethodChannel _channel;

  final StreamController<String> _markerTapController =
      StreamController<String>.broadcast();

  /// Stream of marker tap events (emits the marker id).
  Stream<String> get onMarkerTap => _markerTapController.stream;

  void _bindCallbacks() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'event#onMarkerTap':
          final id = call.arguments as String?;
          if (id != null) _markerTapController.add(id);
          break;
      }
    });
  }

  /// Moves the camera to [target] and optionally sets [zoom].
  Future<void> moveCamera(LatLng target, {double? zoom}) async {
    await _channel.invokeMethod('map#moveCamera', {
      'target': target.toMap(),
      if (zoom != null) 'zoom': zoom,
    });
  }

  /// Animates the camera to fit [northeast] and [southwest] with [padding].
  Future<void> animateToBounds(
    LatLng northeast,
    LatLng southwest, {
    double padding = 50,
  }) async {
    await _channel.invokeMethod('map#animateToBounds', {
      'ne': northeast.toMap(),
      'sw': southwest.toMap(),
      'padding': padding,
    });
  }

  /// Enables/disables traffic overlay.
  Future<void> setTrafficEnabled(bool enabled) async {
    await _channel.invokeMethod('map#setTrafficEnabled', enabled);
  }

  /// Enables/disables the native my-location layer (requires permissions on Android).
  Future<void> setMyLocationEnabled(bool enabled) async {
    await _channel.invokeMethod('map#setMyLocationEnabled', enabled);
  }

  /// Sets map padding to avoid overlaying UI elements.
  Future<void> setPadding(MapPadding padding) async {
    await _channel.invokeMethod('map#setPadding', padding.toMap());
  }

  /// Applies a raw Google Maps JSON style.
  Future<void> setMapStyle(String? mapStyleJson) async {
    await _channel.invokeMethod('map#setStyle', mapStyleJson);
  }

  /// Applies a single-color style tint. If [dark] is true, uses darker contrasts.
  Future<void> setMapColor(Color color, {bool dark = false}) async {
    final style = MapStyleBuilder.tinted(color, dark: dark);
    await setMapStyle(style);
  }

  /// Adds a marker with [options]. Re-adding with same id replaces existing.
  Future<void> addMarker(MarkerOptions options) async {
    await _channel.invokeMethod('markers#add', options.toMap());
  }

  /// Updates a marker by [id]. You may change [position] and/or [rotation].
  Future<void> updateMarker(
    String id, {
    LatLng? position,
    double? rotation,
  }) async {
    await _channel.invokeMethod('markers#update', {
      'id': id,
      if (position != null) 'position': position.toMap(),
      if (rotation != null) 'rotation': rotation,
    });
  }

  /// Removes a marker by [id].
  Future<void> removeMarker(String id) async {
    await _channel.invokeMethod('markers#remove', id);
  }

  /// Removes all markers.
  Future<void> clearMarkers() async {
    await _channel.invokeMethod('markers#clear');
  }

  /// Adds a polyline with [options]. Re-adding with same id replaces existing.
  Future<void> addPolyline(PolylineOptions options) async {
    await _channel.invokeMethod('polylines#add', options.toMap());
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
    await _channel.invokeMethod('polylines#remove', id);
  }

  /// Removes all polylines.
  Future<void> clearPolylines() async {
    await _channel.invokeMethod('polylines#clear');
  }

  /// Captures a PNG snapshot of the current map viewport.
  Future<Uint8List?> takeSnapshot() async {
    final res = await _channel.invokeMethod('map#takeSnapshot');
    if (res is Uint8List) return res;
    return null;
  }

  /// Releases native resources for this map instance.
  Future<void> dispose() async {
    await _channel.invokeMethod('map#dispose');
    await _markerTapController.close();
  }
}
