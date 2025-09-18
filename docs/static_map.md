---
title: Static Map
nav_order: 8
---

# StaticMapView

Widget simples para Google Static Maps (imagem) com polyline/markers opcionais.

```dart
StaticMapView(
  apiKey: 'YOUR_STATIC_MAPS_API_KEY',
  width: 600,
  height: 300,
  center: const LatLng(-23.56, -46.65),
  zoom: 14,
  polyline: const [
    LatLng(-23.561, -46.656),
    LatLng(-23.570, -46.650),
  ],
  polylineColor: const Color(0xFF1976D2),
  polylineWidth: 6,
  markers: const [LatLng(-23.561, -46.656)],
)
```

Use para thumbnails, cards e telas não interativas.

