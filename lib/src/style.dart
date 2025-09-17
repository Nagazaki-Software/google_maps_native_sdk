part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Helpers to build Google Maps JSON styles.
class MapStyleBuilder {
  /// Creates a simple single-color tinted map style based on [color].
  /// If [dark] is true, uses darker contrasts for better readability at night.
  static String tinted(Color color, {bool dark = false}) {
    final hex = _toHexColor(color);
    final textHex = _toHexColor(_adjustLightness(color, dark ? 0.85 : 0.2));
    final strokeHex = _toHexColor(_adjustLightness(color, dark ? -0.6 : -0.3));

    final List<Map<String, dynamic>> style = [
      {
        'elementType': 'geometry',
        'stylers': [
          {'color': hex},
        ],
      },
      {
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': textHex},
        ],
      },
      {
        'elementType': 'labels.text.stroke',
        'stylers': [
          {'color': strokeHex},
        ],
      },
      {
        'featureType': 'poi',
        'elementType': 'geometry',
        'stylers': [
          {'color': hex},
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'geometry',
        'stylers': [
          {'color': _toHexColor(_adjustLightness(color, dark ? 0.15 : 0.4))},
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'geometry',
        'stylers': [
          {'color': _toHexColor(_adjustLightness(color, dark ? -0.2 : -0.4))},
        ],
      },
    ];
    return _jsonEncode(style);
  }
}

String _jsonEncode(Object obj) {
  return const String.fromEnvironment('dart.vm.product') == 'true'
      ? _jsonEncodeFast(obj)
      : _jsonEncodeFast(obj);
}

String _jsonEncodeFast(Object obj) {
  // Minimal JSON encoding for our limited structure (maps/lists/strings/numbers/bools)
  if (obj is List) {
    return '[${obj.map((e) => _jsonEncodeFast(e)).join(',')}]';
  } else if (obj is Map) {
    return '{${obj.entries.map((e) => '"${e.key}":${_jsonEncodeFast(e.value)}').join(',')}}';
  } else if (obj is String) {
    return '"${obj.replaceAll('\\', r'\\').replaceAll('"', r'\"')}"';
  } else if (obj is num || obj is bool) {
    return obj.toString();
  }
  return 'null';
}

String _toHexColor(Color c) {
  final v = _argbColorInt(c);
  return '#${v.toRadixString(16).padLeft(8, '0')}';
}

Color _adjustLightness(Color c, double delta) {
  final hsl = HSLColor.fromColor(c);
  double l = (hsl.lightness + delta).clamp(0.0, 1.0);
  return hsl.withLightness(l).toColor();
}
