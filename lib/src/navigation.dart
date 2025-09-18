part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

class NavigationOptions {
  final String apiKey;
  final LatLng origin;
  final LatLng destination;
  final String mode; // driving, walking, bicycling, transit
  final String language; // e.g. pt-BR
  final bool voiceGuidance;
  final double cameraZoom;
  final double cameraTilt;
  final bool followBearing; // rotate camera with heading
  final double voiceAheadDistanceMeters;
  final double offRouteThresholdMeters;
  final Duration minTimeBetweenReroutes;
  // TTS tuning
  final double ttsRate; // 0.5..1.5
  final double ttsPitch; // 0.5..2.0
  final String? ttsVoice;
  // Speed monitoring
  final bool speedAlertsEnabled;
  final double? speedLimitKmh; // Optional static limit; dynamic integration TBD

  const NavigationOptions({
    required this.apiKey,
    required this.origin,
    required this.destination,
    this.mode = 'driving',
    this.language = 'pt-BR',
    this.voiceGuidance = true,
    this.cameraZoom = 17,
    this.cameraTilt = 45,
    this.followBearing = true,
    this.voiceAheadDistanceMeters = 60,
    this.offRouteThresholdMeters = 50,
    this.minTimeBetweenReroutes = const Duration(seconds: 12),
    this.ttsRate = 0.95,
    this.ttsPitch = 1.0,
    this.ttsVoice,
    this.speedAlertsEnabled = false,
    this.speedLimitKmh,
  });
}

class DirectionsRoute {
  final List<LatLng> points;
  final LatLng northeast;
  final LatLng southwest;
  final List<DirectionStep> steps;
  final int? durationSeconds; // total leg duration if available

  const DirectionsRoute({
    required this.points,
    required this.northeast,
    required this.southwest,
    required this.steps,
    this.durationSeconds,
  });
}

class DirectionStep {
  final LatLng startLocation;
  final LatLng endLocation;
  final int distanceMeters;
  final String instructionHtml;
  final String? maneuver;

  String get instructionText => _stripHtml(instructionHtml);

  const DirectionStep({
    required this.startLocation,
    required this.endLocation,
    required this.distanceMeters,
    required this.instructionHtml,
    this.maneuver,
  });
}

class DirectionsService {
  static Future<DirectionsRoute> fetchRoute({
    required String apiKey,
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
    String language = 'pt-BR',
  }) async {
    final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$mode&language=$language&key=$apiKey&alternatives=false');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw StateError('Directions request failed: HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != 'OK') {
      throw StateError('Directions error: ${json['status']} (${json['error_message'] ?? ''})');
    }
    final routes = json['routes'] as List<dynamic>;
    if (routes.isEmpty) throw StateError('No route found');
    final route = routes[0] as Map<String, dynamic>;
    final overview = (route['overview_polyline'] as Map<String, dynamic>)['points'] as String;
    final bounds = route['bounds'] as Map<String, dynamic>;
    final neM = bounds['northeast'] as Map<String, dynamic>;
    final swM = bounds['southwest'] as Map<String, dynamic>;
    final ne = LatLng((neM['lat'] as num).toDouble(), (neM['lng'] as num).toDouble());
    final sw = LatLng((swM['lat'] as num).toDouble(), (swM['lng'] as num).toDouble());
    final points = PolylineCodec.decode(overview);

    final legs = route['legs'] as List<dynamic>;
    final steps = <DirectionStep>[];
    int? totalDur;
    if (legs.isNotEmpty) {
      final leg = legs[0] as Map<String, dynamic>;
      final dur = (leg['duration'] as Map<String, dynamic>?)?['value'] as num?;
      if (dur != null) totalDur = dur.toInt();
      final rawSteps = leg['steps'] as List<dynamic>;
      for (final s in rawSteps) {
        final sm = s as Map<String, dynamic>;
        final st = sm['start_location'] as Map<String, dynamic>;
        final en = sm['end_location'] as Map<String, dynamic>;
        final dist = (sm['distance'] as Map<String, dynamic>)['value'] as int;
        final instr = sm['html_instructions'] as String? ?? '';
        final man = sm['maneuver'] as String?;
        steps.add(DirectionStep(
          startLocation: LatLng((st['lat'] as num).toDouble(), (st['lng'] as num).toDouble()),
          endLocation: LatLng((en['lat'] as num).toDouble(), (en['lng'] as num).toDouble()),
          distanceMeters: dist,
          instructionHtml: instr,
          maneuver: man,
        ));
      }
    }
    return DirectionsRoute(points: points, northeast: ne, southwest: sw, steps: steps, durationSeconds: totalDur);
  }
}

class NavigationSession {
  final GoogleMapController controller;
  final NavigationOptions options;
  final DirectionsRoute route;
  final StreamSubscription<Position> _sub;
  final FlutterTts? _tts;
  final String polylineId;
  bool _closed = false;

  NavigationSession._(
    this.controller,
    this.options,
    this.route,
    this._sub,
    this._tts,
    this.polylineId,
    this._stateCtl,
    this._instCtl,
    this._progressCtl,
    this._speedCtl,
  );

  // Event streams
  final StreamController<NavState> _stateCtl;
  final StreamController<NavInstruction> _instCtl;
  final StreamController<NavProgress> _progressCtl;
  final StreamController<SpeedAlert> _speedCtl;

  Stream<NavState> get onState => _stateCtl.stream;
  Stream<NavInstruction> get onInstruction => _instCtl.stream;
  Stream<NavProgress> get onProgress => _progressCtl.stream;
  Stream<SpeedAlert> get onSpeedAlert => _speedCtl.stream;

  Future<void> recenter() async {
    // Recenters camera to current route bounds
    await controller.animateToBounds(route.northeast, route.southwest, padding: 60);
  }

  Future<void> overview() async => recenter();

  Future<void> stop({bool clearRoute = true}) async {
    if (_closed) return;
    _closed = true;
    await _sub.cancel();
    if (options.voiceGuidance) {
      try { await _tts?.stop(); } catch (_) {}
    }
    if (clearRoute) {
      try { await controller.removePolyline(polylineId); } catch (_) {}
    }
    await _stateCtl.close();
    await _instCtl.close();
    await _progressCtl.close();
    await _speedCtl.close();
  }
}

class MapNavigator {
  static Future<NavigationSession> start({
    required GoogleMapController controller,
    required NavigationOptions options,
    String polylineId = 'gmns_nav_route',
    Color polylineColor = const Color(0xFF1976D2),
  }) async {
    // Fetch route
    final route = await DirectionsService.fetchRoute(
      apiKey: options.apiKey,
      origin: options.origin,
      destination: options.destination,
      mode: options.mode,
      language: options.language,
    );

    // Draw polyline & fit bounds
    await controller.addPolyline(PolylineOptions(id: polylineId, points: route.points, color: polylineColor, width: 6));
    await controller.animateToBounds(route.northeast, route.southwest, padding: 60);

    // Prepare TTS
    FlutterTts? tts;
    if (options.voiceGuidance) {
      tts = FlutterTts();
      try {
        await tts.setLanguage(options.language);
        await tts.setSpeechRate(options.ttsRate);
        await tts.setPitch(options.ttsPitch);
        if (options.ttsVoice != null) {
          try {
            await tts.setVoice({'name': options.ttsVoice!});
          } catch (_) {}
        }
        await tts.awaitSpeakCompletion(true);
      } catch (_) {}
    }

    // Ensure permissions are handled by the host app
    final locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied || locPerm == LocationPermission.deniedForever) {
      // We don't request here to keep plugin passive; consumer app must request beforehand.
    }

    int spokenStepIndex = -1;
    DateTime lastReroute = DateTime.fromMillisecondsSinceEpoch(0);
    final stateCtl = StreamController<NavState>.broadcast();
    final instCtl = StreamController<NavInstruction>.broadcast();
    final progressCtl = StreamController<NavProgress>.broadcast();
    final speedCtl = StreamController<SpeedAlert>.broadcast();
    stateCtl.add(NavState.navigating);

    // Precompute route length cumulatives for progress
    final cumul = _cumulativeDistances(route.points);
    final totalMeters = cumul.isNotEmpty ? cumul.last : 0.0;

    final sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2),
    ).listen((pos) async {
      final user = LatLng(pos.latitude, pos.longitude);
      final bearing = options.followBearing ? _normalizeBearing(pos.heading.isFinite ? pos.heading : _bearingFromVelocity(pos)) : null;
      // Follow camera
      await controller.animateCamera(user,
          zoom: options.cameraZoom,
          tilt: options.cameraTilt,
          bearing: bearing?.toDouble());

      // Speed monitor
      final speedKmh = (pos.speed.isFinite ? pos.speed : 0.0) * 3.6;
      if (options.speedAlertsEnabled) {
        final limit = options.speedLimitKmh;
        if (limit != null && speedKmh > limit + 2.0) {
          speedCtl.add(SpeedAlert(speedKmh: speedKmh, speedLimitKmh: limit, overLimit: true));
        }
      }

      // Voice guidance on step proximity
      if (options.voiceGuidance && route.steps.isNotEmpty && tts != null) {
        final idx = _closestUpcomingStepIndex(user, route.steps);
        if (idx != null) {
          final step = route.steps[idx];
          final d = _distanceMeters(user, step.startLocation);
          if (d <= options.voiceAheadDistanceMeters && idx > spokenStepIndex) {
            spokenStepIndex = idx;
            final text = _instructionVoiceText(step, options.language);
            try { await tts.speak(text); } catch (_) {}
            instCtl.add(NavInstruction(stepIndex: idx, text: step.instructionText, maneuver: step.maneuver, distanceMeters: d.round()));
          }
        }
      }

      // Progress estimation (distance remaining, ETA)
      if (totalMeters > 0) {
        final traveled = _traveledAlongRoute(user, route.points, cumul);
        final remaining = (totalMeters - traveled).clamp(0.0, totalMeters);
        double? etaSeconds;
        if (route.durationSeconds != null && totalMeters > 1) {
          final frac = remaining / totalMeters;
          etaSeconds = (route.durationSeconds! * frac).toDouble();
        } else if (speedKmh > 1) {
          etaSeconds = (remaining / (speedKmh / 3.6));
        }
        progressCtl.add(NavProgress(distanceRemainingMeters: remaining, etaSeconds: etaSeconds));
      }

      // Simple off-route detection and reroute throttle
      final off = _distanceToPolylineMeters(user, route.points);
      if (off > options.offRouteThresholdMeters) {
        stateCtl.add(NavState.offRoute);
        final now = DateTime.now();
        if (now.difference(lastReroute) >= options.minTimeBetweenReroutes) {
          lastReroute = now;
          stateCtl.add(NavState.rerouting);
          try {
            final newRoute = await DirectionsService.fetchRoute(
              apiKey: options.apiKey,
              origin: user,
              destination: options.destination,
              mode: options.mode,
              language: options.language,
            );
            // Replace polyline
            await controller.addPolyline(PolylineOptions(id: polylineId, points: newRoute.points, color: polylineColor, width: 6));
            // Update bounds softly (do not yank camera too far)
            // Keep following user; bounds not forced on reroute to avoid jitter.
            // Update route reference for progress
            route.points
              ..clear()
              ..addAll(newRoute.points);
            // NOTE: For a fuller model we'd rebuild cumulatives; keeping simple for now.
            stateCtl.add(NavState.navigating);
          } catch (_) {
            // ignore reroute failures silently
            stateCtl.add(NavState.navigating);
          }
        }
      }
    });

    return NavigationSession._(controller, options, route, sub, tts, polylineId, stateCtl, instCtl, progressCtl, speedCtl);
  }
}

// ----------------- helpers -----------------

double _distanceMeters(LatLng a, LatLng b) {
  const R = 6371000.0; // meters
  final dLat = _deg2rad(b.latitude - a.latitude);
  final dLon = _deg2rad(b.longitude - a.longitude);
  final la1 = _deg2rad(a.latitude);
  final la2 = _deg2rad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return R * c;
}

double _deg2rad(double deg) => deg * math.pi / 180.0;

double _distanceToPolylineMeters(LatLng p, List<LatLng> line) {
  if (line.length < 2) return double.infinity;
  double minDist = double.infinity;
  for (var i = 0; i < line.length - 1; i++) {
    final d = _distancePointToSegmentMeters(p, line[i], line[i + 1]);
    if (d < minDist) minDist = d;
  }
  return minDist;
}

double _distancePointToSegmentMeters(LatLng p, LatLng v, LatLng w) {
  // Convert to radians lat/lng then to approximate meters using equirectangular projection around p
  final x1 = _lonToX(v.longitude, p.latitude);
  final y1 = _latToY(v.latitude);
  final x2 = _lonToX(w.longitude, p.latitude);
  final y2 = _latToY(w.latitude);
  final x0 = _lonToX(p.longitude, p.latitude);
  final y0 = _latToY(p.latitude);
  final dx = x2 - x1;
  final dy = y2 - y1;
  final l2 = dx * dx + dy * dy;
  double t = l2 == 0 ? 0 : ((x0 - x1) * dx + (y0 - y1) * dy) / l2;
  t = t.clamp(0.0, 1.0);
  final xx = x1 + t * dx;
  final yy = y1 + t * dy;
  final dd = math.sqrt((x0 - xx) * (x0 - xx) + (y0 - yy) * (y0 - yy));
  return dd;
}

double _latToY(double lat) => lat * 111320.0; // meters per degree approx
double _lonToX(double lon, double atLat) => lon * 111320.0 * math.cos(_deg2rad(atLat));

int? _closestUpcomingStepIndex(LatLng user, List<DirectionStep> steps) {
  if (steps.isEmpty) return null;
  int bestIdx = 0;
  double bestDist = double.infinity;
  for (int i = 0; i < steps.length; i++) {
    final d = _distanceMeters(user, steps[i].startLocation);
    if (d < bestDist) {
      bestDist = d;
      bestIdx = i;
    }
  }
  return bestIdx;
}

String _stripHtml(String html) {
  // Replace basic tags with spaces, remove entities crudely
  final s = html
      .replaceAll('<b>', '')
      .replaceAll('</b>', '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _instructionVoiceText(DirectionStep step, String language) {
  // For now, use stripped HTML text; could augment with maneuver mapping.
  final text = step.instructionText;
  if (language.startsWith('pt')) {
    return text.isEmpty ? 'Siga em frente' : text;
  }
  return text.isEmpty ? 'Continue straight' : text;
}

double? _normalizeBearing(double? bearing) {
  if (bearing == null || !bearing.isFinite) return null;
  double b = bearing % 360.0;
  if (b < 0) b += 360.0;
  return b;
}

double _bearingFromVelocity(Position pos) {
  // If speed is significant and we have previous positions this would be better; fallback: 0.
  return 0;
}

// ----- Navigation events & helpers -----

enum NavState { navigating, offRoute, rerouting }

class NavInstruction {
  final int stepIndex;
  final String text;
  final String? maneuver;
  final int distanceMeters;
  const NavInstruction({required this.stepIndex, required this.text, this.maneuver, required this.distanceMeters});
}

class NavProgress {
  final double distanceRemainingMeters;
  final double? etaSeconds;
  const NavProgress({required this.distanceRemainingMeters, required this.etaSeconds});
}

class SpeedAlert {
  final double speedKmh;
  final double? speedLimitKmh;
  final bool overLimit;
  const SpeedAlert({required this.speedKmh, this.speedLimitKmh, required this.overLimit});
}

List<double> _cumulativeDistances(List<LatLng> pts) {
  final res = <double>[];
  double acc = 0.0;
  for (int i = 0; i < pts.length; i++) {
    if (i > 0) acc += _distanceMeters(pts[i - 1], pts[i]);
    res.add(acc);
  }
  return res;
}

double _traveledAlongRoute(LatLng p, List<LatLng> line, List<double> cumul) {
  if (line.length < 2 || cumul.isEmpty) return 0.0;
  double bestDist = double.infinity;
  int bestIdx = 0;
  double projFrac = 0.0; // 0..1 on segment
  for (int i = 0; i < line.length - 1; i++) {
    final a = line[i];
    final b = line[i + 1];
    final pRes = _projectPointFraction(p, a, b);
    final segDist = _distancePointToSegmentMeters(p, a, b);
    if (segDist < bestDist) {
      bestDist = segDist;
      bestIdx = i;
      projFrac = pRes;
    }
  }
  final base = cumul[bestIdx];
  final segLen = _distanceMeters(line[bestIdx], line[bestIdx + 1]);
  return base + segLen * projFrac;
}

double _projectPointFraction(LatLng p, LatLng v, LatLng w) {
  final x1 = _lonToX(v.longitude, p.latitude);
  final y1 = _latToY(v.latitude);
  final x2 = _lonToX(w.longitude, p.latitude);
  final y2 = _latToY(w.latitude);
  final x0 = _lonToX(p.longitude, p.latitude);
  final y0 = _latToY(p.latitude);
  final dx = x2 - x1;
  final dy = y2 - y1;
  final l2 = dx * dx + dy * dy;
  if (l2 == 0) {
    return 0.0;
  }
  var t = ((x0 - x1) * dx + (y0 - y1) * dy) / l2;
  if (t < 0) {
    t = 0;
  } else if (t > 1) {
    t = 1;
  }
  return t;
}
