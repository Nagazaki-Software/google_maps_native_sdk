---
title: Widget
nav_order: 3
---

# GoogleMapView

Widget que renderiza o mapa nativo (Android/iOS) ou JS (Web).

Construtor principal:
```dart
GoogleMapView({
  required CameraPosition initialCameraPosition,
  bool trafficEnabled = false,
  bool buildingsEnabled = true,
  bool myLocationEnabled = false,
  String? mapStyleJson,
  MapPadding padding = const MapPadding(),
  bool clusterEnabled = false,
  bool liteMode = false,           // Android
  bool indoorEnabled = false,
  bool indoorLevelPicker = false,  // Android
  String? mapId,                   // Cloud styling
  MapCreatedCallback? onMapCreated,
  String? webApiKey,               // Web
})
```

Exemplo completo:
```dart
GoogleMapView(
  initialCameraPosition: const CameraPosition(
    target: LatLng(-23.561, -46.656),
    zoom: 14,
    tilt: 0,
    bearing: 0,
  ),
  trafficEnabled: true,
  myLocationEnabled: false,
  padding: const MapPadding(bottom: 100),
  mapStyleJson: MapStyleBuilder.tinted(const Color(0xFF0D47A1), dark: false),
  onMapCreated: (c) async {
    await c.onMapLoaded;
    await c.addMarker(MarkerOptions(
      id: 'user',
      position: const LatLng(-23.561, -46.656),
      title: 'Você está aqui',
    ));
  },
)
```

Tipos úteis:
- `LatLng(lat, lng)`
- `CameraPosition(target, zoom, tilt, bearing)`
- `MapPadding(left, top, right, bottom)`

