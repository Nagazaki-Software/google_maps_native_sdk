---
title: Câmera
nav_order: 12
---

# Câmera

Controle de posição, zoom, tilt e bearing.

## Mover e animar
```dart
await controller.moveCamera(const LatLng(-23.56, -46.65), zoom: 13);
await controller.animateCamera(
  const LatLng(-23.565, -46.652),
  zoom: 15,
  tilt: 30,
  bearing: 120,
  durationMs: 800,
);
```

## Enquadrar limites (bounds)
```dart
await controller.animateToBounds(
  const LatLng(-23.55, -46.60), // NE
  const LatLng(-23.60, -46.70), // SW
  padding: 60,
);
```

## Dicas
- Use `setPadding` para acomodar bottom sheets e barras.
- Aplique `await controller.onMapLoaded` antes de animar com tilt/bearing.

