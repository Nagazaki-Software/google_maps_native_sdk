part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

typedef SpeedLimitProvider = Future<double?> Function(LatLng position);

enum VehicleRotationSource { course, route, deviceHeading }

class NavigationOptions {
  final String apiKey;
  final LatLng origin;
  final LatLng destination;
  final List<Waypoint> intermediates; // Routes v2 waypoints
  final String mode; // driving, walking, bicycling, transit
  final String language; // e.g. pt-BR
  final bool voiceGuidance;
  final double cameraZoom;
  final double cameraTilt;
  final bool followBearing; // rotate camera with heading
  // Heading/compass controls
  final bool useDeviceHeading; // use device compass/rotation at low speed
  final double lowSpeedAutoRotateKmh; // freeze below this speed
  final double headingFilterAlpha; // 0..1 smoothing for heading
  final double voiceAheadDistanceMeters; // deprecated in favor de approachSpeakMeters
  final List<double> approachSpeakMeters; // ex.: [400, 150, 30, 10]
  final double arrivalThresholdMeters; // distÃ¢ncia para considerar chegada
  final double offRouteThresholdMeters;
  final Duration minTimeBetweenReroutes;
  // TTS tuning
  final double ttsRate; // 0.5..1.5
  final double ttsPitch; // 0.5..2.0
  final String? ttsVoice;
  final bool interruptOnNewInstruction; // stop current TTS before speaking next
  final bool androidRequestAudioFocus; // request AudioFocus for navigation
  final bool iosDuckOthers; // set iOS category to duck others
  // Speed monitoring
  final bool speedAlertsEnabled;
  final double? speedLimitKmh; // Limite estÃ¡tico opcional
  final SpeedLimitProvider? speedLimitProvider; // Provedor dinÃ¢mico opcional

  // Map matching e snapping
  final bool snapToRoute;
  final double mapMatchingToleranceMeters;

  // Roteamento
  final bool rerouteOnOffRoute;
  final bool useRoutesV2; // usar Routes API v2 para navegaÃ§Ã£o (passos localizados)

  // SimulaÃ§Ã£o (para testes/demos)
  final double? simulationSpeedKmh; // quando definido, usa simulaÃ§Ã£o em vez de GPS

  const NavigationOptions({
    required this.apiKey,
    required this.origin,
    required this.destination,
    this.intermediates = const [],
    this.mode = 'driving',
    this.language = 'pt-BR',
    this.voiceGuidance = true,
    this.cameraZoom = 17,
    this.cameraTilt = 45,
    this.followBearing = true,
    this.useDeviceHeading = true,
    this.lowSpeedAutoRotateKmh = 3.0,
    this.headingFilterAlpha = 0.25,
    this.voiceAheadDistanceMeters = 60,
    this.approachSpeakMeters = const [400, 150, 30, 10],
    this.arrivalThresholdMeters = 25,
    this.offRouteThresholdMeters = 50,
    this.minTimeBetweenReroutes = const Duration(seconds: 12),
    this.ttsRate = 0.95,
    this.ttsPitch = 1.0,
    this.ttsVoice,
    this.interruptOnNewInstruction = true,
    this.androidRequestAudioFocus = true,
    this.iosDuckOthers = true,
    this.speedAlertsEnabled = false,
    this.speedLimitKmh,
    this.speedLimitProvider,
    this.snapToRoute = true,
    this.mapMatchingToleranceMeters = 30,
    this.rerouteOnOffRoute = true,
    this.useRoutesV2 = false,
    this.simulationSpeedKmh,
    this.routeColor,
    this.routeWidth = 6,
    this.showVehicleMarker = false,
    this.vehicleMarkerId = 'gmns_vehicle',
    this.vehicleIconUrl,
    this.vehicleIconAnchorU = 0.5,
    this.vehicleIconAnchorV = 0.62,
    this.vehicleIconDp = 48,
    this.vehicleRotationSource = VehicleRotationSource.course,
  });

  // Aparência/tema da rota e marcador do veículo (declarações)
  // Nota: os campos são declarados aqui para evitar conflitos com acentos
  // em comentários em ambientes Windows. A ordem não impacta o Dart.
  final Color? routeColor;
  final double routeWidth;
  final bool showVehicleMarker;
  final String vehicleMarkerId;
  final String? vehicleIconUrl;
  final double vehicleIconAnchorU;
  final double vehicleIconAnchorV;
  final double vehicleIconDp;
  final VehicleRotationSource vehicleRotationSource;
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

class _NavShared {
  bool closed = false;
  bool paused = false;
  Timer? simTimer;
  double simSpeedKmh = 0.0;
}

class NavigationSession {
  final GoogleMapController controller;
  final NavigationOptions options;
  final DirectionsRoute route;
  final StreamSubscription<Position>? _sub;
  final FlutterTts? _tts;
  final String polylineId;
  final _NavShared _shared;
  StreamSubscription<double>? _headingSub;

  NavigationSession._(
    this.controller,
    this.options,
    this.route,
    this._sub,
    this._tts,
    this.polylineId,
    this._shared,
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

  bool get isPaused => _shared.paused;

  Future<void> pause() async {
    if (_shared.paused) return;
    _shared.paused = true;
    _sub?.pause();
    _stateCtl.add(NavState.paused);
  }

  Future<void> resume() async {
    if (!_shared.paused) return;
    _shared.paused = false;
    _sub?.resume();
    _stateCtl.add(NavState.navigating);
  }

  bool get isSimulating => _shared.simTimer != null;
  double get simulationSpeedKmh => _shared.simSpeedKmh;
  Future<void> setSimulationSpeed(double kmh) async {
    _shared.simSpeedKmh = kmh.clamp(1.0, 200.0);
  }

  Future<void> stop({bool clearRoute = true}) async {
    if (_shared.closed) return;
    _shared.closed = true;
    try { await _sub?.cancel(); } catch (_) {}
    try { _shared.simTimer?.cancel(); } catch (_) {}
    try { await _headingSub?.cancel(); } catch (_) {}
    if (options.voiceGuidance) {
      try { await _tts?.stop(); } catch (_) {}
    }
    if (defaultTargetPlatform == TargetPlatform.android && options.androidRequestAudioFocus) {
      try { await AudioFocus.abandon(); } catch (_) {}
    }
    if (clearRoute) {
      try { await controller.removePolyline(polylineId); } catch (_) {}
    }
    if (options.showVehicleMarker) {
      try { await controller.removeMarker(options.vehicleMarkerId); } catch (_) {}
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
    // Fetch route (Directions classic ou Routes v2)
    final route = await _fetchNavigationRoute(options);

    // Draw polyline & fit bounds
    final Color routeClr = options.routeColor ?? polylineColor;
    await controller.addPolyline(PolylineOptions(id: polylineId, points: route.points, color: routeClr, width: options.routeWidth));
    await controller.animateToBounds(route.northeast, route.southwest, padding: 60);

    // Prepare TTS / Audio
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
        // iOS ducking
        if (options.iosDuckOthers) {
          try { await (tts as dynamic).setIosAudioCategory('playback', ['duckOthers']); } catch (_) {}
        }
      } catch (_) {}
      // Android AudioFocus
      if (defaultTargetPlatform == TargetPlatform.android && options.androidRequestAudioFocus) {
        try { await AudioFocus.request(); } catch (_) {}
      }
    }

    // Ensure permissions are handled by the host app
    final locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied || locPerm == LocationPermission.deniedForever) {
      // We don't request here to keep plugin passive; consumer app must request beforehand.
    }

    DateTime lastReroute = DateTime.fromMillisecondsSinceEpoch(0);
    final stateCtl = StreamController<NavState>.broadcast();
    final instCtl = StreamController<NavInstruction>.broadcast();
    final progressCtl = StreamController<NavProgress>.broadcast();
    final speedCtl = StreamController<SpeedAlert>.broadcast();
    stateCtl.add(NavState.navigating);

    // Precompute route length cumulatives for progress
    final cumul = _cumulativeDistances(route.points);
    final totalMeters = cumul.isNotEmpty ? cumul.last : 0.0;

    // Estado compartilhado runtime
    final shared = _NavShared();

    // Device heading (compass/rotation)
    double? latestHeading;
    StreamSubscription<double>? headingSub;
    _AngleSmoother? headingSmoother = options.headingFilterAlpha > 0 ? _AngleSmoother(options.headingFilterAlpha) : null;
    if (options.followBearing && options.useDeviceHeading) {
      try {
        headingSub = DeviceHeading.stream.listen((h) { latestHeading = h; });
      } catch (_) {}
    }

    // Fala por aproximaÃ§Ã£o em mÃºltiplos limiares
    final Map<int, Set<double>> spokenByStep = {};

    // Auxiliares de limite de velocidade dinÃ¢mico
    double? dynSpeedLimit;
    DateTime lastSpeedFetch = DateTime.fromMillisecondsSinceEpoch(0);
    bool vehicleMarkerAdded = false;

    // FunÃ§Ã£o para processar uma atualizaÃ§Ã£o de posiÃ§Ã£o (GPS ou simulaÃ§Ã£o)
    Future<void> onPosition(LatLng user, {double speedKmh = 0.0, double? course}) async {
      if (shared.closed || shared.paused) return;

      // Snapping e bearing
      LatLng camTarget = user;
      double? camBearing;
      double? routeBearing;
      if (options.snapToRoute && route.points.length >= 2) {
        final np = _nearestPointOnPolyline(user, route.points);
        camTarget = np.point;
        final a = route.points[np.segIndex];
        final b = route.points[np.segIndex + 1];
        routeBearing = _normalizeBearing(_bearingDegrees(a, b));
      }

      // Determine camera bearing
      if (options.followBearing) {
        final speed = speedKmh.isFinite ? speedKmh : 0.0;
        double? candidate;
        if (speed >= options.lowSpeedAutoRotateKmh) {
          // Moving: prefer course from location; fallback to route bearing
          candidate = _normalizeBearing(course) ?? routeBearing;
        } else {
          // Low speed / stationary: prefer device heading; fallback to route bearing
          candidate = _normalizeBearing(latestHeading) ?? routeBearing;
        }
        if (candidate != null) {
          if (headingSmoother != null) {
            camBearing = headingSmoother.update(candidate);
          } else {
            camBearing = candidate;
          }
        }
      }

      // Vehicle marker: add/update if enabled
      if (options.showVehicleMarker) {
        final markerPos = options.snapToRoute ? camTarget : user;
        if (!vehicleMarkerAdded) {
          try {
            await controller.addMarker(MarkerOptions(
              id: options.vehicleMarkerId,
              position: markerPos,
              iconUrl: options.vehicleIconUrl,
              iconDp: options.vehicleIconDp,
              anchorU: options.vehicleIconAnchorU,
              anchorV: options.vehicleIconAnchorV,
              rotation: (options.vehicleRotationSource == VehicleRotationSource.deviceHeading)
                  ? (camBearing ?? 0)
                  : (options.vehicleRotationSource == VehicleRotationSource.route
                      ? (routeBearing ?? camBearing ?? 0)
                      : (_normalizeBearing(course) ?? routeBearing ?? camBearing ?? 0)),
              zIndex: 9999,
            ));
            vehicleMarkerAdded = true;
          } catch (_) {}
        } else {
          double? rot;
          switch (options.vehicleRotationSource) {
            case VehicleRotationSource.course:
              rot = _normalizeBearing(course) ?? routeBearing ?? camBearing;
              break;
            case VehicleRotationSource.route:
              rot = routeBearing ?? _normalizeBearing(course) ?? camBearing;
              break;
            case VehicleRotationSource.deviceHeading:
              rot = camBearing ?? routeBearing ?? _normalizeBearing(course);
              break;
          }
          try {
            await controller.updateMarker(options.vehicleMarkerId, position: markerPos, rotation: rot);
          } catch (_) {}
        }
      }

      await controller.animateCamera(
        camTarget,
        zoom: options.cameraZoom,
        tilt: options.cameraTilt,
        bearing: options.followBearing ? camBearing : null,
      );

      // Velocidade/alertas (opcional provider dinÃ¢mico)
      if (options.speedAlertsEnabled) {
        final now = DateTime.now();
        if (options.speedLimitProvider != null && now.difference(lastSpeedFetch) > const Duration(seconds: 20)) {
          lastSpeedFetch = now;
          try { dynSpeedLimit = await options.speedLimitProvider!(user); } catch (_) {}
        }
        final limit = dynSpeedLimit ?? options.speedLimitKmh;
        if (limit != null && speedKmh > limit + 2.0) {
          speedCtl.add(SpeedAlert(speedKmh: speedKmh, speedLimitKmh: limit, overLimit: true));
        }
      }

      // Progresso/ETA
      if (totalMeters > 0) {
        final traveled = _traveledAlongRoute(camTarget, route.points, cumul);
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

      // Chegada
      final dDest = _distanceMeters(camTarget, options.destination);
        if (dDest <= options.arrivalThresholdMeters) {
          stateCtl.add(NavState.arrived);
          if (options.voiceGuidance && tts != null) {
            final txt = options.language.startsWith('pt') ? 'VocÃª chegou ao destino' : 'You have arrived at your destination';
            try { await tts.speak(txt); } catch (_) {}
          }
          return;
        }

      // InstruÃ§Ãµes por passo (aproximaÃ§Ã£o em mÃºltiplos limiares)
      if (options.voiceGuidance && route.steps.isNotEmpty && tts != null) {
        // Passo mais prÃ³ximo adiante
        int idx = _closestUpcomingStepIndex(camTarget, route.steps) ?? 0;
        final step = route.steps[idx];
        final d = _distanceMeters(camTarget, step.startLocation);
        final spokenSet = spokenByStep.putIfAbsent(idx, () => <double>{});
        for (final th in options.approachSpeakMeters) {
          if (!spokenSet.contains(th) && d <= th) {
            spokenSet.add(th);
            final text = _instructionVoiceText(step, options.language);
            try {
              if (options.interruptOnNewInstruction) { try { await tts.stop(); } catch (_) {} }
              await tts.speak(text);
            } catch (_) {}
            instCtl.add(NavInstruction(stepIndex: idx, text: step.instructionText, maneuver: step.maneuver, distanceMeters: d.round()));
            break;
          }
        }
      }

      // Off-route e Reroute
      final off = _distanceToPolylineMeters(camTarget, route.points);
      if (options.rerouteOnOffRoute && off > options.offRouteThresholdMeters) {
        stateCtl.add(NavState.offRoute);
        final now = DateTime.now();
        if (now.difference(lastReroute) >= options.minTimeBetweenReroutes) {
          lastReroute = now;
          stateCtl.add(NavState.rerouting);
          try {
            if (options.useRoutesV2) {
              final res = await RoutesApi.computeRoutes(
                apiKey: options.apiKey,
                origin: Waypoint(location: camTarget),
                destination: Waypoint(location: options.destination),
                intermediates: options.intermediates,
                languageCode: options.language,
                alternatives: false,
              );
              if (res.routes.isNotEmpty) {
                final r = res.routes.first;
                final newSteps = <DirectionStep>[];
                for (final leg in r.legs) {
                  for (final st in leg.steps) {
                    LatLng? s;
                    LatLng? e;
                    if (st.points.isNotEmpty) { s = st.points.first; e = st.points.last; }
                    newSteps.add(DirectionStep(
                      startLocation: s ?? camTarget,
                      endLocation: e ?? options.destination,
                      distanceMeters: st.distanceMeters ?? 0,
                      instructionHtml: st.instruction ?? '',
                      maneuver: st.maneuver,
                    ));
                  }
                }
                await controller.addPolyline(PolylineOptions(id: polylineId, points: r.points, color: routeClr, width: options.routeWidth));
                route.points..clear()..addAll(r.points);
                route.steps..clear()..addAll(newSteps);
                cumul..clear()..addAll(_cumulativeDistances(route.points));
                spokenByStep.clear();
              }
            } else {
              final newRoute = await DirectionsService.fetchRoute(
                apiKey: options.apiKey,
                origin: camTarget,
                destination: options.destination,
                mode: options.mode,
                language: options.language,
              );
              await controller.addPolyline(PolylineOptions(id: polylineId, points: newRoute.points, color: routeClr, width: options.routeWidth));
              route.points..clear()..addAll(newRoute.points);
              cumul..clear()..addAll(_cumulativeDistances(route.points));
              spokenByStep.clear();
            }
            stateCtl.add(NavState.navigating);
          } catch (_) {
            stateCtl.add(NavState.navigating);
          }
        }
      }
    }

    StreamSubscription<Position>? sub;
    if (options.simulationSpeedKmh != null && totalMeters > 0) {
      // SimulaÃ§Ã£o baseada no polyline
      double progress = 0.0; // metros ao longo da rota
      shared.simSpeedKmh = options.simulationSpeedKmh!.clamp(1.0, 200.0);
      shared.simTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (shared.paused || shared.closed) return;
        final spd = shared.simSpeedKmh.clamp(1.0, 200.0);
        progress = (progress + spd / 3.6).clamp(0.0, totalMeters);
        final interp = _interpolateAlongRoute(route.points, cumul, progress);
        await onPosition(interp.position, speedKmh: spd, course: interp.bearing);
      });
    } else {
      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2),
      ).listen((pos) async {
        final user = LatLng(pos.latitude, pos.longitude);
        final speedKmh = (pos.speed.isFinite ? pos.speed : 0.0) * 3.6;
        final course = pos.heading.isFinite ? pos.heading : _bearingFromVelocity(pos);
        await onPosition(user, speedKmh: speedKmh, course: course);
      });
    }

    final sess = NavigationSession._(controller, options, route, sub, tts, polylineId, shared, stateCtl, instCtl, progressCtl, speedCtl);
    sess._headingSub = headingSub;
    return sess;
  }

  static Future<DirectionsRoute> _fetchNavigationRoute(NavigationOptions options) async {
    if (options.useRoutesV2) {
      final res = await RoutesApi.computeRoutes(
        apiKey: options.apiKey,
        origin: Waypoint(location: options.origin),
        destination: Waypoint(location: options.destination),
        intermediates: options.intermediates,
        languageCode: options.language,
        alternatives: false,
      );
      if (res.routes.isEmpty) {
        throw StateError('No route from Routes API v2');
      }
      final r = res.routes.first;
      final steps = <DirectionStep>[];
      for (final leg in r.legs) {
        for (final st in leg.steps) {
          LatLng? start;
          LatLng? end;
          if (st.points.isNotEmpty) {
            start = st.points.first;
            end = st.points.last;
          }
          steps.add(DirectionStep(
            startLocation: start ?? options.origin,
            endLocation: end ?? options.destination,
            distanceMeters: st.distanceMeters ?? 0,
            instructionHtml: st.instruction ?? '',
            maneuver: st.maneuver,
          ));
        }
      }
      final ne = r.northeast ?? _polyMax(r.points);
      final sw = r.southwest ?? _polyMin(r.points);
      return DirectionsRoute(points: r.points, northeast: ne, southwest: sw, steps: steps, durationSeconds: r.durationSeconds);
    }
    return await DirectionsService.fetchRoute(
      apiKey: options.apiKey,
      origin: options.origin,
      destination: options.destination,
      mode: options.mode,
      language: options.language,
    );
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

enum NavState { navigating, offRoute, rerouting, paused, arrived }

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

// ---------- advanced helpers ----------

class _NearestPoint {
  final LatLng point;
  final int segIndex; // index of segment start (uses segIndex and segIndex+1)
  final double t; // 0..1 within the segment
  const _NearestPoint(this.point, this.segIndex, this.t);
}

_NearestPoint _nearestPointOnPolyline(LatLng p, List<LatLng> line) {
  double bestDist = double.infinity;
  int bestIdx = 0;
  double bestT = 0.0;
  LatLng bestPoint = line.first;
  for (int i = 0; i < line.length - 1; i++) {
    final a = line[i];
    final b = line[i + 1];
    final t = _projectPointFraction(p, a, b);
    final lat = a.latitude + (b.latitude - a.latitude) * t;
    final lng = a.longitude + (b.longitude - a.longitude) * t;
    final q = LatLng(lat, lng);
    final d = _distanceMeters(p, q);
    if (d < bestDist) {
      bestDist = d;
      bestIdx = i;
      bestT = t;
      bestPoint = q;
    }
  }
  return _NearestPoint(bestPoint, bestIdx, bestT);
}

double _bearingDegrees(LatLng a, LatLng b) {
  final lat1 = _deg2rad(a.latitude);
  final lat2 = _deg2rad(b.latitude);
  final dLon = _deg2rad(b.longitude - a.longitude);
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  var brng = math.atan2(y, x) * 180.0 / math.pi;
  if (brng < 0) brng += 360.0;
  return brng;
}

class _InterpResult { final LatLng position; final double bearing; _InterpResult(this.position, this.bearing); }

_InterpResult _interpolateAlongRoute(List<LatLng> pts, List<double> cumul, double progressMeters) {
  if (pts.length < 2) return _InterpResult(pts.first, 0);
  progressMeters = progressMeters.clamp(0.0, cumul.last);
  int idx = 0;
  while (idx < cumul.length - 1 && cumul[idx + 1] < progressMeters) {
    idx++;
  }
  final base = cumul[idx];
  final segLen = (cumul[idx + 1] - base).clamp(0.001, double.infinity);
  final t = ((progressMeters - base) / segLen).clamp(0.0, 1.0);
  final a = pts[idx];
  final b = pts[idx + 1];
  final lat = a.latitude + (b.latitude - a.latitude) * t;
  final lng = a.longitude + (b.longitude - a.longitude) * t;
  final br = _bearingDegrees(a, b);
  return _InterpResult(LatLng(lat, lng), br);
}

// (Step mapping removido por enquanto; pode ser reintroduzido se necessÃ¡rio.)

LatLng _polyMax(List<LatLng> pts) {
  if (pts.isEmpty) return const LatLng(0, 0);
  double maxLat = pts.first.latitude;
  double maxLng = pts.first.longitude;
  for (final p in pts) {
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return LatLng(maxLat, maxLng);
}

LatLng _polyMin(List<LatLng> pts) {
  if (pts.isEmpty) return const LatLng(0, 0);
  double minLat = pts.first.latitude;
  double minLng = pts.first.longitude;
  for (final p in pts) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
  }
  return LatLng(minLat, minLng);
}
