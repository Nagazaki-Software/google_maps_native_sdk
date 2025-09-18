part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Minimal helper hub to make it easier to use from FlutterFlow custom actions.
/// Holds a single active controller/session and exposes simple methods.
class GmnsNavHub {
  static GoogleMapController? _controller;
  static NavigationSession? _session;
  static RoutesResponse? _lastRoutes;
  static int? _activeRouteIndex;

  static void setController(GoogleMapController controller) {
    _controller = controller;
  }

  static GoogleMapController? get controller => _controller;
  static NavigationSession? get session => _session;
  static RoutesResponse? get lastRoutes => _lastRoutes;
  static int? get activeRouteIndex => _activeRouteIndex;

  /// Computes routes, draws all alternatives as separate polylines, and selects one as active.
  /// Returns the number of routes.
  static Future<int> computeRoutesAndDraw({
    required String apiKey,
    required LatLng origin,
    required LatLng destination,
    List<Waypoint> intermediates = const [],
    RouteModifiers? modifiers,
    bool alternatives = true,
    Units units = Units.metric,
    String languageCode = 'pt-BR',
    PolylineQuality polylineQuality = PolylineQuality.high,
    int activeIndex = 0,
  }) async {
    final c = _controller;
    if (c == null) throw StateError('Controller not set. Call setController first.');
    final res = await RoutesApi.computeRoutes(
      apiKey: apiKey,
      origin: Waypoint(location: origin),
      destination: Waypoint(location: destination),
      intermediates: intermediates,
      modifiers: modifiers,
      alternatives: alternatives,
      units: units,
      languageCode: languageCode,
      polylineQuality: polylineQuality,
    );
    _lastRoutes = res;
    // Draw all alternatives
    for (final r in res.routes) {
      final id = 'gmns_alt_${r.index}';
      await c.addPolyline(PolylineOptions(
        id: id,
        points: r.points,
        color: r.index == activeIndex ? const Color(0xFF1976D2) : const Color(0x661976D2),
        width: r.index == activeIndex ? 8 : 6,
      ));
    }
    _activeRouteIndex = activeIndex;
    // Fit bounds if possible
    final active = res.routes.firstWhere((e) => e.index == activeIndex, orElse: () => res.routes.first);
    if (active.points.isNotEmpty) {
      final ne = active.points.reduce((a, b) => LatLng(a.latitude > b.latitude ? a.latitude : b.latitude, a.longitude > b.longitude ? a.longitude : b.longitude));
      final sw = active.points.reduce((a, b) => LatLng(a.latitude < b.latitude ? a.latitude : b.latitude, a.longitude < b.longitude ? a.longitude : b.longitude));
      await c.animateToBounds(ne, sw, padding: 60);
    }
    return res.routes.length;
  }

  /// Switches visual active route among those drawn by [computeRoutesAndDraw].
  static Future<void> chooseActiveRoute(int index) async {
    final c = _controller;
    final res = _lastRoutes;
    if (c == null || res == null) return;
    for (final r in res.routes) {
      final id = 'gmns_alt_${r.index}';
      // Re-add polyline with new style (simple way to recolor)
      await c.addPolyline(PolylineOptions(
        id: id,
        points: r.points,
        color: r.index == index ? const Color(0xFF1976D2) : const Color(0x661976D2),
        width: r.index == index ? 8 : 6,
      ));
    }
    _activeRouteIndex = index;
  }

  /// Starts TBT navigation to [destination] from [origin] using Directions (lightweight).
  static Future<bool> startNavigation({
    required String apiKey,
    required LatLng origin,
    required LatLng destination,
    String language = 'pt-BR',
    bool voiceGuidance = true,
    double cameraZoom = 17,
    double cameraTilt = 45,
    bool useRoutesV2 = false,
    List<Waypoint> intermediates = const [],
  }) async {
    final c = _controller;
    if (c == null) return false;
    _session = await MapNavigator.start(
      controller: c,
      options: NavigationOptions(
        apiKey: apiKey,
        origin: origin,
        destination: destination,
        language: language,
        voiceGuidance: voiceGuidance,
        cameraZoom: cameraZoom,
        cameraTilt: cameraTilt,
        useRoutesV2: useRoutesV2,
        intermediates: intermediates,
      ),
    );
    return true;
  }

  static Future<void> stopNavigation() async {
    final s = _session;
    _session = null;
    if (s != null) {
      await s.stop();
    }
  }

  static Future<void> recenter() async {
    final s = _session;
    await s?.recenter();
  }

  static Future<void> overview() async {
    final s = _session;
    await s?.overview();
  }
}
