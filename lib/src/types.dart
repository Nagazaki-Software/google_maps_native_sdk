part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Geographic coordinate (latitude/longitude) in WGS84.
class LatLng {
  final double latitude;
  final double longitude;

  /// Creates a coordinate at [latitude], [longitude].
  const LatLng(this.latitude, this.longitude);

  Map<String, double> toMap() => {'lat': latitude, 'lng': longitude};

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Initial camera setup for the map.
class CameraPosition {
  final LatLng target;
  final double zoom;
  final double tilt;
  final double bearing;

  /// Creates a camera positioned at [target] and [zoom] level (default 14).
  const CameraPosition({
    required this.target,
    this.zoom = 14,
    this.tilt = 0,
    this.bearing = 0,
  });

  /// Serializes to the map format expected by the native layers.
  Map<String, dynamic> toMap() => {
        'target': target.toMap(),
        'zoom': zoom,
        'tilt': tilt,
        'bearing': bearing,
      };
}

/// Marker configuration.
class MarkerOptions {
  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;
  final String? iconUrl; // http(s), asset:// or data:
  final double anchorU; // 0..1
  final double anchorV; // 0..1
  final double rotation;
  final bool draggable;
  final double zIndex;

  /// Creates marker options. [id] must be unique.
  const MarkerOptions({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.iconUrl,
    this.anchorU = 0.5,
    this.anchorV = 0.62,
    this.rotation = 0,
    this.draggable = false,
    this.zIndex = 0,
  });

  /// Serializes to the map format expected by the native layers.
  Map<String, dynamic> toMap() => {
        'id': id,
        'position': position.toMap(),
        if (title != null) 'title': title,
        if (snippet != null) 'snippet': snippet,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'anchorU': anchorU,
        'anchorV': anchorV,
        'rotation': rotation,
        'draggable': draggable,
        'zIndex': zIndex,
      };
}

/// Polyline configuration.
class PolylineOptions {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool geodesic;
  final bool dotted;

  /// Creates polyline options. [id] must be unique.
  const PolylineOptions({
    required this.id,
    required this.points,
    this.color = const Color(0xFF1B5E20),
    this.width = 6,
    this.geodesic = false,
    this.dotted = false,
  });

  /// Serializes to the map format expected by the native layers.
  Map<String, dynamic> toMap() => {
        'id': id,
        'points': points.map((e) => e.toMap()).toList(growable: false),
        'color': _argbColorInt(color),
        'width': width,
        'geodesic': geodesic,
        'dotted': dotted,
      };
}

/// Padding to be applied around the map viewport (in logical pixels).
class MapPadding {
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Creates padding with [left], [top], [right], [bottom].
  const MapPadding({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  /// Serializes to the map format expected by the native layers.
  Map<String, double> toMap() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };
}

/// Utilities related to polylines.
class PolylineCodec {
  /// Decodes a Google-encoded polyline string into a list of [LatLng].
  static List<LatLng> decode(String encoded) {
    // First try precision 1e5; if out-of-range, retry with 1e6 (Polyline6)
    List<LatLng> pts = _decodeWithPrecision(encoded, 1e5);
    bool outOfRange = false;
    for (final p in pts) {
      if (p.latitude.abs() > 90.0 || p.longitude.abs() > 180.0) { outOfRange = true; break; }
    }
    if (outOfRange) {
      pts = _decodeWithPrecision(encoded, 1e6);
    }
    return pts;
  }

  static List<LatLng> _decodeWithPrecision(String encoded, double precision) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 1 ? (result >> 1) : ~(result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 1 ? (result >> 1) : ~(result >> 1));
      lng += dlng;
      points.add(LatLng(lat / precision, lng / precision));
    }
    return points;
  }
}

int _argbColorInt(Color c) {
  try {
    final dynamic d = c;
    final int a = ((d.a as double) * 255.0).round() & 0xff;
    final int r = ((d.r as double) * 255.0).round() & 0xff;
    final int g = ((d.g as double) * 255.0).round() & 0xff;
    final int b = ((d.b as double) * 255.0).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  } catch (_) {
    final s = c.toString();
    final match = RegExp(r'0x([0-9a-fA-F]{8})').firstMatch(s);
    if (match != null) {
      return int.parse(match.group(1)!, radix: 16);
    }
    return 0xFF000000; // opaque black fallback
  }
}
