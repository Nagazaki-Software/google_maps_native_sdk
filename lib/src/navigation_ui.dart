part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Day/Night theme behavior for the native Navigation UI.
enum NavUiThemeMode { auto, day, night }

/// Minimal options to launch the native Google Navigation UI (when available).
///
/// Note: This requires access to the Google Maps Navigation SDK on Android/iOS.
/// If not available, the native side will return an error or present a placeholder.
class NavUiOptions {
  final String apiKey; // Google Navigation/Routes key
  final LatLng origin;
  final LatLng destination;
  final List<Waypoint> intermediates;
  final String languageCode; // e.g., 'pt-BR'

  // Theming (platform support may vary and be limited by the SDK)
  final Color? colorPrimary;
  final Color? colorOnPrimary;
  final Color? colorSurface;
  final Color? colorOnSurface;
  final String? mapId; // Cloud Map ID when supported
  final NavUiThemeMode themeMode; // auto/day/night preference

  const NavUiOptions({
    required this.apiKey,
    required this.origin,
    required this.destination,
    this.intermediates = const [],
    this.languageCode = 'pt-BR',
    this.colorPrimary,
    this.colorOnPrimary,
    this.colorSurface,
    this.colorOnSurface,
    this.mapId,
    this.themeMode = NavUiThemeMode.auto,
  });

  Map<String, dynamic> toMap() => {
        'apiKey': apiKey,
        'origin': origin.toMap(),
        'destination': destination.toMap(),
        if (intermediates.isNotEmpty)
          'intermediates': intermediates.map((w) => {
                if (w.location != null) 'location': w.location!.toMap(),
                if (w.placeId != null) 'placeId': w.placeId,
                if (w.via != null) 'via': w.via,
                if (w.sideOfRoad != null) 'sideOfRoad': w.sideOfRoad,
              }).toList(growable: false),
        'languageCode': languageCode,
        if (colorPrimary != null) 'colorPrimary': _argbColorInt(colorPrimary!),
        if (colorOnPrimary != null) 'colorOnPrimary': _argbColorInt(colorOnPrimary!),
        if (colorSurface != null) 'colorSurface': _argbColorInt(colorSurface!),
        if (colorOnSurface != null) 'colorOnSurface': _argbColorInt(colorOnSurface!),
        if (mapId != null) 'mapId': mapId,
        'themeMode': themeMode.name,
      };
}

/// Bridge to the native Navigation UI host.
class NavigationUi {
  static const MethodChannel _ch = MethodChannel('google_maps_native_sdk/nav_ui');

  /// Returns whether the native Navigation SDK is available on this platform.
  static Future<bool> isAvailable() async {
    try {
      final ok = await _ch.invokeMethod<bool>('nav_ui#isAvailable');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launches the native Navigation UI with [options]. Returns true if opened.
  static Future<bool> start(NavUiOptions options) async {
    final args = options.toMap();
    final ok = await _ch.invokeMethod<bool>('nav_ui#start', args);
    return ok ?? false;
  }

  /// Closes the native Navigation UI if it is currently presented.
  static Future<void> stop() async {
    try {
      await _ch.invokeMethod('nav_ui#stop');
    } catch (_) {}
  }
}

