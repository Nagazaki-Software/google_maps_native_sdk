// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;
import 'dart:typed_data';
// Use the web-specific UI library for PlatformView registry on Flutter ≥ 3.13.
import 'dart:ui_web' as ui_web; // for platformViewRegistry

import 'package:flutter/widgets.dart';
import 'web_host_types.dart';

class _WebMapHost implements WebMapHost {
  final js.JsObject map; // google.maps.Map
  js.JsObject? _trafficLayer; // google.maps.TrafficLayer

  final Map<String, js.JsObject> _markers = {}; // id -> Marker
  final Map<String, js.JsObject> _polylines = {}; // id -> Polyline

  void Function(String id)? _onMarkerTap;
  void Function()? _onMapLoaded;

  _WebMapHost(this.map) {
    final maps = js.context['google']['maps'];
    final onTilesLoaded = js.allowInterop(() => _onMapLoaded?.call());
    maps['event'].callMethod('addListener', [map, 'tilesloaded', onTilesLoaded]);
  }

  @override
  void setOnMarkerTap(void Function(String id)? cb) { _onMarkerTap = cb; }

  @override
  void setOnMapLoaded(void Function()? cb) { _onMapLoaded = cb; }

  js.JsObject _latLng(dynamic p) => js.JsObject(js.context['google']['maps']['LatLng'], [p.latitude as num, p.longitude as num]);

  @override
  Future<void> moveCamera(dynamic target, {double? zoom, double? tilt, double? bearing}) async {
    map.callMethod('setCenter', [_latLng(target)]);
    if (zoom != null) map.callMethod('setZoom', [zoom]);
    final opts = js.JsObject.jsify({
      if (tilt != null) 'tilt': tilt,
      if (bearing != null) 'heading': bearing,
    });
    if (opts['tilt'] != null || opts['heading'] != null) {
      map.callMethod('setOptions', [opts]);
    }
  }

  @override
  Future<void> animateToBounds(dynamic ne, dynamic sw, {double padding = 50}) async {
    final bounds = js.JsObject(js.context['google']['maps']['LatLngBounds'], [
      _latLng(sw),
      _latLng(ne),
    ]);
    map.callMethod('fitBounds', [bounds]);
  }

  @override
  Future<void> animateCamera(dynamic target, {double? zoom, double? tilt, double? bearing, int? durationMs}) async {
    if (durationMs == null || durationMs <= 0) {
      await moveCamera(target, zoom: zoom, tilt: tilt, bearing: bearing);
      return;
    }

    final startCenter = map.callMethod('getCenter', []);
    final centerObj = js.JsObject.fromBrowserObject(startCenter);
    final startLat = centerObj.callMethod('lat', []) as num;
    final startLng = centerObj.callMethod('lng', []) as num;
    final startZoom = map.callMethod('getZoom', []) as num;
    final st = map.callMethod('getTilt', []);
    final sh = map.callMethod('getHeading', []);
    final startTilt = st is num ? st : 0;
    final startHeading = sh is num ? sh : 0;

    final endLat = target.latitude as num;
    final endLng = target.longitude as num;
    final endZoom = (zoom ?? startZoom.toDouble()) as num;
    final endTilt = (tilt ?? startTilt.toDouble()) as num;
    final endHeading = (bearing ?? startHeading.toDouble()) as num;

    final total = durationMs.toDouble();
    num? startTs;

    void step(num highResTs) {
      startTs ??= highResTs;
      final elapsed = highResTs - startTs!;
      final t = (elapsed / total).clamp(0, 1);
      final lat = startLat + (endLat - startLat) * t;
      final lng = startLng + (endLng - startLng) * t;
      final z = startZoom + (endZoom - startZoom) * t;
      final ti = startTilt + (endTilt - startTilt) * t;
      final hd = startHeading + (endHeading - startHeading) * t;
      map.callMethod('setCenter', [js.JsObject(js.context['google']['maps']['LatLng'], [lat, lng])]);
      map.callMethod('setZoom', [z]);
      map.callMethod('setOptions', [js.JsObject.jsify({'tilt': ti, 'heading': hd})]);
      if (t < 1) {
        html.window.requestAnimationFrame(step);
      }
    }

    html.window.requestAnimationFrame(step);
  }

  @override
  Future<void> setTrafficEnabled(bool enabled) async {
    final maps = js.context['google']['maps'];
    _trafficLayer ??= js.JsObject(maps['TrafficLayer']);
    _trafficLayer!.callMethod('setMap', [enabled ? map : null]);
  }

  @override
  Future<void> setPadding(dynamic padding) async {
    // Not directly supported; could emulate via CSS padding around element.
  }

  @override
  Future<void> setMapStyle(String? json) async {
    if (json == null) {
      map.callMethod('setOptions', [js.JsObject.jsify({'styles': null})]);
      return;
    }
    try {
      final styles = js.context['JSON'].callMethod('parse', [json]);
      map.callMethod('setOptions', [js.JsObject.jsify({'styles': styles})]);
    } catch (_) {}
  }

  @override
  Future<void> addMarker(dynamic options) async {
    final maps = js.context['google']['maps'];
    final marker = js.JsObject(maps['Marker'], [
      js.JsObject.jsify({
        'map': map,
        'position': _latLng(options.position),
        'title': options.title,
        if (options.iconUrl != null) 'icon': options.iconUrl,
        'draggable': options.draggable,
        'zIndex': options.zIndex,
      })
    ]);
    // Events
    final clickCb = js.allowInterop(() => _onMarkerTap?.call(options.id as String));
    maps['event'].callMethod('addListener', [marker, 'click', clickCb]);
    final old = _markers[options.id];
    if (old != null) old.callMethod('setMap', [null]);
    _markers[options.id] = marker;
  }

  @override
  Future<void> updateMarker(String id, {dynamic position, double? rotation}) async {
    final m = _markers[id];
    if (m == null) return;
    if (position != null) m.callMethod('setPosition', [_latLng(position)]);
    // Rotation not supported on default markers in JS API; to support, swap to Symbol or AdvancedMarker.
  }

  @override
  Future<void> removeMarker(String id) async {
    final m = _markers.remove(id);
    m?.callMethod('setMap', [null]);
  }

  @override
  Future<void> clearMarkers() async {
    for (final m in _markers.values) {
      m.callMethod('setMap', [null]);
    }
    _markers.clear();
  }

  @override
  Future<void> addPolyline(dynamic options) async {
    final maps = js.context['google']['maps'];
    final path = (options.points as List).map((e) => _latLng(e)).toList();
    final poly = js.JsObject(maps['Polyline'], [
      js.JsObject.jsify({
        'map': map,
        'path': js.JsArray.from(path),
        'strokeColor': _strokeHex(options.color),
        'strokeWeight': options.width as num,
        'geodesic': options.geodesic as bool,
        if (options.dotted as bool) 'strokeOpacity': 0.8,
      })
    ]);
    final old = _polylines[options.id as String];
    if (old != null) old.callMethod('setMap', [null]);
    _polylines[options.id as String] = poly;
  }

  @override
  Future<void> updatePolylinePoints(String id, List<dynamic> points) async {
    final poly = _polylines[id];
    if (poly == null) return;
    final path = js.JsArray.from(points.map((e) => _latLng(e)));
    poly.callMethod('setPath', [path]);
  }

  @override
  Future<void> removePolyline(String id) async {
    final p = _polylines.remove(id);
    p?.callMethod('setMap', [null]);
  }

  @override
  Future<void> clearPolylines() async {
    for (final p in _polylines.values) {
      p.callMethod('setMap', [null]);
    }
    _polylines.clear();
  }

  @override
  Future<Uint8List?> takeSnapshot() async {
    // Not supported in JS API directly.
    return null;
  }

  @override
  Future<void> dispose() async {
    await clearMarkers();
    await clearPolylines();
    _trafficLayer?.callMethod('setMap', [null]);
  }
}

final _pendingInitializers = <void Function(html.DivElement)>[];
bool _registeredFactory = false;
const _viewType = 'google_maps_native_sdk/map_view';

Widget buildWebGoogleMapView({
  required dynamic initialCameraPosition,
  required bool trafficEnabled,
  required bool buildingsEnabled,
  required bool myLocationEnabled,
  required String? mapStyleJson,
  required dynamic padding,
  required String? webApiKey,
  required void Function(WebMapHost host) onHostReady,
}) {
  if (!_registeredFactory) {
    // Register a single factory; each call creates a fresh element and runs the pending initializer.
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final el = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';
      if (_pendingInitializers.isNotEmpty) {
        final init = _pendingInitializers.removeAt(0);
        scheduleMicrotask(() => init(el));
      }
      return el;
    });
    _registeredFactory = true;
  }

  // Push initializer for this instance
  _pendingInitializers.add((el) async {
    await _ensureJsLoaded(webApiKey);
    final maps = js.context['google']['maps'];
    final map = js.JsObject(maps['Map'], [
      el,
      js.JsObject.jsify({
        'center': js.JsObject(maps['LatLng'], [initialCameraPosition.target.latitude as num, initialCameraPosition.target.longitude as num]),
        'zoom': initialCameraPosition.zoom as num,
        if ((initialCameraPosition as dynamic).tilt != null) 'tilt': (initialCameraPosition as dynamic).tilt as num,
        if ((initialCameraPosition as dynamic).bearing != null) 'heading': (initialCameraPosition as dynamic).bearing as num,
        'gestureHandling': 'greedy',
        'fullscreenControl': false,
        'mapTypeControl': false,
        'streetViewControl': false,
      })
    ]);

    final host = _WebMapHost(map);
    // Initialize style/traffic
    if (mapStyleJson != null) await host.setMapStyle(mapStyleJson);
    if (trafficEnabled) await host.setTrafficEnabled(true);

    // Notify host ready; view.dart will create the real controller and attach callbacks
    onHostReady(host);
  });

  return const HtmlElementView(viewType: _viewType);
}


Completer<void>? _mapsScriptLoader;
String _strokeHex(dynamic colorObj) {
  try {
    final intVal = (colorObj as dynamic).value as int;
    final hex = intVal.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}';
  } catch (_) {
    try {
      final intVal = colorObj as int;
      final hex = intVal.toRadixString(16).padLeft(8, '0');
      return '#${hex.substring(2)}';
    } catch (_) {
      return '#1976D2';
    }
  }
}
Future<void> _ensureJsLoaded(String? apiKey) async {
  // Already available
  if (js.context.hasProperty('google') && js.context['google'].hasProperty('maps')) return;
  if (_mapsScriptLoader != null) return _mapsScriptLoader!.future;
  _mapsScriptLoader = Completer<void>();
  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..defer = true
    ..async = true
    ..src = _buildMapsJsUrl(apiKey);
  script.onError.listen((event) {
    _mapsScriptLoader?.completeError(StateError('Failed to load Google Maps JS API'));
    _mapsScriptLoader = null;
  });
  script.onLoad.listen((event) {
    _mapsScriptLoader?.complete();
  });
  html.document.head!.append(script);
  await _mapsScriptLoader!.future;
  // Use importLibrary to ensure core library is ready (when available)
  try {
    final maps = js.context['google']['maps'];
    if (maps.hasProperty('importLibrary')) {
      final c = Completer<void>();
      final promise = maps.callMethod('importLibrary', ['maps']);
      promise.callMethod('then', [
        js.allowInterop((_) => c.complete()),
        js.allowInterop((e) => c.completeError(e ?? 'importLibrary failed')),
      ]);
      await c.future;
    }
  } catch (_) {}
  return;
}

String _buildMapsJsUrl(String? apiKey) {
  final key = apiKey ?? '';
  final params = <String, String>{
    if (key.isNotEmpty) 'key': key,
    'libraries': 'geometry',
    'v': 'weekly',
  };
  final q = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
  return 'https://maps.googleapis.com/maps/api/js?$q';
}
