---
title: Routes API v2
nav_order: 6
---

# Routes API v2

Cliente para Google Routes API (Directions v2) e Route Matrix, agora com mais detalhes: viewport, legs/steps com instruções, labels e duração estática.

Recursos:
- Rotas alternativas, polyline em alta qualidade ou overview
- Modificadores (evitar pedágios/rodovias/balsas), passes de pedágio
- Waypoints avançados (via/stopover, sideOfRoad, placeId)
- Idioma/unidades e FieldMask configurável
- Viewport (bounds), labels da rota, duração estática
- Legs e Steps com polyline, distância, instrução e maneuver
- Matriz de ETAs em lote

## Rotas e desenho no mapa
```dart
final res = await RoutesApi.computeRoutes(
  apiKey: 'YOUR_ROUTES_API_KEY',
  origin: Waypoint(location: const LatLng(-23.561, -46.656)),
  destination: Waypoint(location: const LatLng(-23.570, -46.650)),
  intermediates: const [Waypoint(location: LatLng(-23.566, -46.653), via: true, sideOfRoad: true)],
  modifiers: const RouteModifiers(avoidHighways: true),
  alternatives: true,
  languageCode: 'pt-BR',
);
for (final r in res.routes) {
  await controller.addPolyline(PolylineOptions(
    id: 'r${r.index}', points: r.points, color: const Color(0xFF1976D2), width: 6,
  ));
}

// Enquadrar usando viewport da rota (quando presente)
final active = res.routes.first;
if (active.northeast != null && active.southwest != null) {
  await controller.animateToBounds(active.northeast!, active.southwest!, padding: 60);
}

// Labels da rota
print('labels: ${active.routeLabels}');

// Steps com instruções
for (final leg in active.legs) {
  for (final step in leg.steps) {
    print('step: ${step.instruction} | maneuver=${step.maneuver} | dist=${step.distanceMeters}m');
  }
}
```

## Matriz de ETAs
```dart
final elements = await RoutesApi.computeRouteMatrix(
  apiKey: 'YOUR_ROUTES_API_KEY',
  origins: const [Waypoint(location: LatLng(-23.56, -46.65))],
  destinations: const [Waypoint(location: LatLng(-23.57, -46.66)), Waypoint(location: LatLng(-23.58, -46.67))],
  mode: TravelMode.drive,
  languageCode: 'pt-BR',
);
for (final e in elements) {
  print('o=${e.originIndex} d=${e.destinationIndex} dur=${e.durationSeconds}s dist=${e.distanceMeters}m');
}
```

Tipos principais: `Waypoint`, `RouteModifiers`, `RoutesResponse -> RouteData (points/distance/duration/staticDuration/tollInfo/viewport/labels/legs[steps])`.
