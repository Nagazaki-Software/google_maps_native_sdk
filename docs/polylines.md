---
title: Polylines
nav_order: 11
---

# Polylines

## Adicionar e atualizar
```dart
// Adicionar
await controller.addPolyline(PolylineOptions(
  id: 'routeA',
  points: const [
    LatLng(-23.560, -46.650),
    LatLng(-23.565, -46.655),
    LatLng(-23.570, -46.660),
  ],
  color: Color(0xFF1976D2),
  width: 6,
  geodesic: false,
));

// Atualizar pontos (sem recriar)
await controller.updatePolylinePoints('routeA', const [
  LatLng(-23.560, -46.650),
  LatLng(-23.566, -46.656),
  LatLng(-23.575, -46.662),
]);
```

## A partir de polyline codificado
```dart
await controller.addPolylineFromEncoded(
  'routeB',
  'u`rgFf}mkG...'; // string codificada do Google
);
```

## Remover
```dart
await controller.removePolyline('routeA');
await controller.clearPolylines();
```

Boas práticas:
- Para “rastro” em tempo real, acumule pontos e chame `updatePolylinePoints` (evite remover e recriar a cada frame).
- Use `animateToBounds` para enquadrar a rota com padding confortável.

