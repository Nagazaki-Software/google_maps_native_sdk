part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Simple Google Static Maps widget with optional polyline.
class StaticMapView extends StatelessWidget {
  final String apiKey;
  final int width;
  final int height;
  final LatLng center;
  final int zoom; // 0..21
  final List<LatLng>? polyline;
  final Color polylineColor;
  final int polylineWidth;
  final List<LatLng>? markers;

  const StaticMapView({
    super.key,
    required this.apiKey,
    required this.width,
    required this.height,
    required this.center,
    this.zoom = 14,
    this.polyline,
    this.polylineColor = const Color(0xFF1976D2),
    this.polylineWidth = 6,
    this.markers,
  });

  @override
  Widget build(BuildContext context) {
    final uri = _buildUrl();
    return Image.network(uri.toString(), width: width.toDouble(), height: height.toDouble(), fit: BoxFit.cover);
  }

  Uri _buildUrl() {
    final params = <String, String>{
      'size': '${width}x$height',
      'center': '${center.latitude},${center.longitude}',
      'zoom': '$zoom',
      'key': apiKey,
      'scale': '2',
    };
    final paths = <String>[];
    if (polyline != null && polyline!.isNotEmpty) {
      final colorHex = _hexColor(polylineColor);
      final sb = StringBuffer('weight:$polylineWidth|color:$colorHex');
      for (final p in polyline!) {
        sb.write('|${p.latitude},${p.longitude}');
      }
      paths.add(sb.toString());
    }
    final markersParam = markers == null || markers!.isEmpty
        ? null
        : markers!.map((m) => '${m.latitude},${m.longitude}').join('|');
    final query = Map<String, dynamic>.from(params);
    for (final path in paths) {
      query.putIfAbsent('path', () => path);
    }
    if (markersParam != null) {
      query['markers'] = markersParam;
    }
    return Uri.https('maps.googleapis.com', '/maps/api/staticmap', query.map((k, v) => MapEntry(k, '$v')));
  }

  String _hexColor(Color c) {
    final v = _argbColorInt(c);
    final hex = v.toRadixString(16).padLeft(8, '0');
    return '0x$hex';
  }
}

