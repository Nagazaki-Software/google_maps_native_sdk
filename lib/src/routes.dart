part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Google Routes API (v2) lightweight client.
///
/// Supports: alternative routes, route modifiers (avoid tolls/highways/ferries),
/// advanced waypoints (side-of-road, via/stopover), toll info, units/language,
/// configurable FieldMask, and Compute Route Matrix for batch ETAs.
class RoutesApi {
  static const _baseRoutes = 'https://routes.googleapis.com/directions/v2:computeRoutes';
  static const _baseMatrix = 'https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix';

  /// Computes routes between [origin] and [destination].
  ///
  /// Provide [apiKey] and optionally [intermediates], [modifiers], [units], [language],
  /// [alternatives], [tollPasses], and a custom [fieldMask].
  /// When [fieldMask] is omitted a minimal default is used.
  static Future<RoutesResponse> computeRoutes({
    required String apiKey,
    required Waypoint origin,
    required Waypoint destination,
    List<Waypoint> intermediates = const [],
    RouteModifiers? modifiers,
    TravelMode mode = TravelMode.drive,
    Units units = Units.metric,
    String languageCode = 'pt-BR',
    bool alternatives = true,
    List<String>? tollPasses,
    String? fieldMask,
    PolylineQuality polylineQuality = PolylineQuality.high,
  }) async {
    final body = <String, dynamic>{
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      if (intermediates.isNotEmpty)
        'intermediates': intermediates.map((w) => w.toJson()).toList(growable: false),
      'travelMode': mode.nameGoogle,
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': alternatives,
      'languageCode': languageCode,
      'units': units.nameGoogle,
      'polylineQuality': polylineQuality.nameGoogle,
      if (modifiers != null) 'routeModifiers': modifiers.toJson(),
      if (tollPasses != null && tollPasses.isNotEmpty) 'routeModifiers': {
        ...(modifiers?.toJson() ?? <String, dynamic>{}),
        'tollPasses': tollPasses,
      },
    };

    final mask = fieldMask ?? [
      // Route level
      'routes.distanceMeters',
      'routes.duration',
      'routes.staticDuration',
      'routes.polyline.encodedPolyline',
      'routes.travelAdvisory.tollInfo',
      'routes.viewport',
      'routes.routeLabels',
      // Legs & Steps
      'routes.legs.distanceMeters',
      'routes.legs.duration',
      'routes.legs.steps.distanceMeters',
      'routes.legs.steps.polyline.encodedPolyline',
      'routes.legs.steps.navigationInstruction',
      // Optional localized texts
      'routes.legs.steps.localizedValues',
      'routes.localizedValues',
    ].join(',');

    final uri = Uri.parse('$_baseRoutes?key=$apiKey');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': mask,
      },
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw StateError('Routes API HTTP ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return RoutesResponse.fromJson(json);
  }

  /// Computes an ETA matrix for multiple origins/destinations.
  /// Returns one element per origin x destination (sparse list with indices).
  static Future<List<RouteMatrixElement>> computeRouteMatrix({
    required String apiKey,
    required List<Waypoint> origins,
    required List<Waypoint> destinations,
    TravelMode mode = TravelMode.drive,
    Units units = Units.metric,
    String languageCode = 'pt-BR',
    String? fieldMask,
  }) async {
    final body = <String, dynamic>{
      'origins': origins.map((o) => {'waypoint': o.toJson()}).toList(growable: false),
      'destinations': destinations.map((d) => {'waypoint': d.toJson()}).toList(growable: false),
      'travelMode': mode.nameGoogle,
      'languageCode': languageCode,
      'units': units.nameGoogle,
      'routingPreference': 'TRAFFIC_AWARE',
    };
    final mask = fieldMask ?? 'originIndex,destinationIndex,duration,distanceMeters,status';
    final uri = Uri.parse('$_baseMatrix?key=$apiKey');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': mask,
      },
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw StateError('Route Matrix HTTP ${res.statusCode}: ${res.body}');
    }
    final lines = (jsonDecode(res.body) as List<dynamic>?) ?? const [];
    return [
      for (final item in lines) RouteMatrixElement.fromJson(item as Map<String, dynamic>)
    ];
  }
}

/// Polyline quality options for encoded output.
enum PolylineQuality { high, overview }

extension on PolylineQuality {
  String get nameGoogle => this == PolylineQuality.high ? 'HIGH_QUALITY' : 'OVERVIEW';
}

/// Travel mode mapping to Google enum.
enum TravelMode { drive, walk, bicycle, twoWheeler }

extension on TravelMode {
  String get nameGoogle {
    switch (this) {
      case TravelMode.drive:
        return 'DRIVE';
      case TravelMode.walk:
        return 'WALK';
      case TravelMode.bicycle:
        return 'BICYCLE';
      case TravelMode.twoWheeler:
        return 'TWO_WHEELER';
    }
  }
}

/// Units system.
enum Units { metric, imperial }

extension on Units {
  String get nameGoogle => this == Units.metric ? 'METRIC' : 'IMPERIAL';
}

/// Waypoint with advanced options.
class Waypoint {
  final LatLng? location;
  final String? placeId;
  final bool? via; // true = via point (no stopover)
  final bool? sideOfRoad;

  const Waypoint({this.location, this.placeId, this.via, this.sideOfRoad});

  Map<String, dynamic> toJson() {
    return {
      if (location != null) 'location': {'latLng': {'latitude': location!.latitude, 'longitude': location!.longitude}},
      if (placeId != null) 'placeId': placeId,
      if (via != null) 'via': via,
      if (sideOfRoad != null) 'sideOfRoad': sideOfRoad,
    };
  }
}

/// Route constraints (avoid tolls/highways/ferries) and toll passes.
class RouteModifiers {
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;

  const RouteModifiers({this.avoidTolls = false, this.avoidHighways = false, this.avoidFerries = false});

  Map<String, dynamic> toJson() => {
        'avoidTolls': avoidTolls,
        'avoidHighways': avoidHighways,
        'avoidFerries': avoidFerries,
      };
}

/// Response wrapper for computeRoutes.
class RoutesResponse {
  final List<RouteData> routes;

  const RoutesResponse({required this.routes});

  factory RoutesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['routes'] as List<dynamic>? ?? const []);
    return RoutesResponse(routes: [
      for (var i = 0; i < list.length; i++) RouteData.fromJson(list[i] as Map<String, dynamic>, index: i),
    ]);
  }
}

/// Route data with polyline, distance, duration, toll info and details.
class RouteData {
  final int index;
  final List<LatLng> points;
  final int? distanceMeters;
  final int? durationSeconds;
  final int? staticDurationSeconds;
  final TollInfo? tollInfo;
  final LatLng? northeast; // from viewport.high
  final LatLng? southwest; // from viewport.low
  final List<RouteLegData> legs;
  final List<String> routeLabels;

  const RouteData({
    required this.index,
    required this.points,
    this.distanceMeters,
    this.durationSeconds,
    this.staticDurationSeconds,
    this.tollInfo,
    this.northeast,
    this.southwest,
    this.legs = const [],
    this.routeLabels = const [],
  });

  factory RouteData.fromJson(Map<String, dynamic> json, {required int index}) {
    final poly = ((json['polyline'] as Map<String, dynamic>?)?['encodedPolyline'] as String?) ?? '';
    final dist = (json['distanceMeters'] as num?)?.toInt();
    final durStr = json['duration'] as String?; // e.g. '123s'
    final dur = durStr == null ? null : int.tryParse(durStr.replaceAll('s', ''));
    final sDurStr = json['staticDuration'] as String?;
    final sDur = sDurStr == null ? null : int.tryParse(sDurStr.replaceAll('s', ''));
    final advisory = json['travelAdvisory'] as Map<String, dynamic>?;
    final tollInfo = advisory == null ? null : TollInfo.fromJson(advisory['tollInfo'] as Map<String, dynamic>?);
    // viewport
    LatLng? ne;
    LatLng? sw;
    final viewport = json['viewport'] as Map<String, dynamic>?;
    if (viewport != null) {
      final high = viewport['high'] as Map<String, dynamic>?;
      final low = viewport['low'] as Map<String, dynamic>?;
      if (high != null) {
        final hl = high['latitude'] as num?;
        final hg = high['longitude'] as num?;
        if (hl != null && hg != null) ne = LatLng(hl.toDouble(), hg.toDouble());
      }
      if (low != null) {
        final ll = low['latitude'] as num?;
        final lg = low['longitude'] as num?;
        if (ll != null && lg != null) sw = LatLng(ll.toDouble(), lg.toDouble());
      }
    }
    // labels
    final labels = <String>[];
    final rawLabels = json['routeLabels'] as List<dynamic>?;
    if (rawLabels != null) {
      for (final l in rawLabels) {
        final s = l?.toString();
        if (s != null) labels.add(s);
      }
    }
    // legs & steps
    final legsJson = json['legs'] as List<dynamic>?;
    final legs = <RouteLegData>[];
    if (legsJson != null) {
      for (final li in legsJson) {
        final m = li as Map<String, dynamic>;
        legs.add(RouteLegData.fromJson(m));
      }
    }
    return RouteData(
      index: index,
      points: poly.isEmpty ? const [] : PolylineCodec.decode(poly),
      distanceMeters: dist,
      durationSeconds: dur,
      staticDurationSeconds: sDur,
      tollInfo: tollInfo,
      northeast: ne,
      southwest: sw,
      legs: legs,
      routeLabels: labels,
    );
  }
}

class RouteLegData {
  final int? distanceMeters;
  final int? durationSeconds;
  final List<RouteStepData> steps;
  const RouteLegData({this.distanceMeters, this.durationSeconds, this.steps = const []});

  factory RouteLegData.fromJson(Map<String, dynamic> json) {
    final dist = (json['distanceMeters'] as num?)?.toInt();
    final durStr = json['duration'] as String?;
    final dur = durStr == null ? null : int.tryParse(durStr.replaceAll('s', ''));
    final stepsJson = json['steps'] as List<dynamic>?;
    final steps = <RouteStepData>[];
    if (stepsJson != null) {
      for (final si in stepsJson) {
        steps.add(RouteStepData.fromJson(si as Map<String, dynamic>));
      }
    }
    return RouteLegData(distanceMeters: dist, durationSeconds: dur, steps: steps);
  }
}

class RouteStepData {
  final int? distanceMeters;
  final List<LatLng> points;
  final String? instruction;
  final String? maneuver;
  const RouteStepData({this.distanceMeters, this.points = const [], this.instruction, this.maneuver});

  factory RouteStepData.fromJson(Map<String, dynamic> json) {
    final dist = (json['distanceMeters'] as num?)?.toInt();
    final poly = ((json['polyline'] as Map<String, dynamic>?)?['encodedPolyline'] as String?) ?? '';
    String? instruction = (json['navigationInstruction'] as Map<String, dynamic>?)?['instructions'] as String?;
    String? maneuver = (json['navigationInstruction'] as Map<String, dynamic>?)?['maneuver'] as String?;
    return RouteStepData(
      distanceMeters: dist,
      points: poly.isEmpty ? const [] : PolylineCodec.decode(poly),
      instruction: instruction,
      maneuver: maneuver,
    );
  }
}

class TollInfo {
  final List<TollPrice> estimatedPrice;
  const TollInfo({required this.estimatedPrice});
  factory TollInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TollInfo(estimatedPrice: []);
    final prices = (json['estimatedPrice'] as List<dynamic>? ?? const []);
    return TollInfo(estimatedPrice: [for (final p in prices) TollPrice.fromJson(p as Map<String, dynamic>)]);
  }
}

class TollPrice {
  final String currencyCode;
  final String units; // integer units as string
  final int nanos; // fractional in nanos
  const TollPrice({required this.currencyCode, required this.units, required this.nanos});
  factory TollPrice.fromJson(Map<String, dynamic> json) => TollPrice(
        currencyCode: (json['currencyCode'] as String?) ?? 'USD',
        units: (json['units']?.toString()) ?? '0',
        nanos: (json['nanos'] as num?)?.toInt() ?? 0,
      );
}

/// One origin/destination ETA entry from ComputeRouteMatrix.
class RouteMatrixElement {
  final int originIndex;
  final int destinationIndex;
  final int? durationSeconds;
  final int? distanceMeters;
  final String? status;

  const RouteMatrixElement({
    required this.originIndex,
    required this.destinationIndex,
    this.durationSeconds,
    this.distanceMeters,
    this.status,
  });

  factory RouteMatrixElement.fromJson(Map<String, dynamic> json) => RouteMatrixElement(
        originIndex: (json['originIndex'] as num?)?.toInt() ?? 0,
        destinationIndex: (json['destinationIndex'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['duration'] as String?)?.replaceAll('s', '').let(int.tryParse),
        distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
        status: json['status'] as String?,
      );
}

extension _Let<T> on T? {
  R? let<R>(R? Function(T v) f) => this == null ? null : f(this as T);
}
