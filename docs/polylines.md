---
title: Polylines (HQ/Polyline6)
nav_order: 14
---

# Polylines de alta qualidade

- `RoutesApi.computeRoutes` usa por padrão `polylineQuality=HIGH_QUALITY`.
- O decodificador interno detecta automaticamente polylines com precisão 1e5 e 1e6 (Polyline6).
- Para desenhar, use `GoogleMapController.addPolyline` com `PolylineOptions` (largura e cor personalizáveis).

Exemplo:
```dart
final res = await RoutesApi.computeRoutes(
  apiKey: 'KEY',
  origin: Waypoint(location: const LatLng(-23.56, -46.65)),
  destination: Waypoint(location: const LatLng(-23.58, -46.66)),
  alternatives: false,
);
final route = res.routes.first;
await controller.addPolyline(PolylineOptions(
  id: 'route',
  points: route.points, // decodificado automaticamente (1e5 ou Polyline6)
  color: const Color(0xFF1976D2),
  width: 6,
));
```

