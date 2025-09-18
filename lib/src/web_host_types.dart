import 'dart:typed_data';

/// Bridge interface implemented by the Web map host.
abstract class WebMapHost {
  // Event sinks
  void setOnMarkerTap(void Function(String id)? cb);
  void setOnMapLoaded(void Function()? cb);
  Future<void> moveCamera(dynamic target, {double? zoom, double? tilt, double? bearing});
  Future<void> animateToBounds(dynamic ne, dynamic sw, {double padding = 50});
  Future<void> animateCamera(dynamic target, {double? zoom, double? tilt, double? bearing, int? durationMs});
  Future<void> setTrafficEnabled(bool enabled);
  Future<void> setPadding(dynamic padding);
  Future<void> setMapStyle(String? json);
  Future<void> addMarker(dynamic markerOptions);
  Future<void> updateMarker(String id, {dynamic position, double? rotation});
  Future<void> removeMarker(String id);
  Future<void> clearMarkers();
  Future<void> addPolyline(dynamic polylineOptions);
  Future<void> updatePolylinePoints(String id, List<dynamic> points);
  Future<void> removePolyline(String id);
  Future<void> clearPolylines();
  Future<Uint8List?> takeSnapshot();
  Future<void> dispose();
}
