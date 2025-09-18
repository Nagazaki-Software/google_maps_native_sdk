---
title: Controller
nav_order: 4
---

# GoogleMapController

Controla a instância do mapa. Você o recebe via `onMapCreated` e pode aguardar `onMapLoaded`.

Eventos:
```dart
await controller.onMapLoaded; // mapa pronto
controller.onMarkerTap.listen((id) => print('Marker $id tocado'));
```

## Câmera
- `moveCamera(target, {zoom, tilt, bearing})`
- `animateCamera(target, {zoom, tilt, bearing, durationMs})`
- `animateToBounds(northeast, southwest, {padding = 50})`

Exemplo:
```dart
await c.animateToBounds(
  const LatLng(-23.55, -46.60),
  const LatLng(-23.60, -46.70),
  padding: 60,
);
```

## Estilo e UI
- `setTrafficEnabled(bool)`
- `setMyLocationEnabled(bool)` [Android/iOS]
- `setPadding(MapPadding)`
- `setMapStyle(String? json)`
- `setMapColor(Color color, {bool dark = false})` (helper JSON)
- `setIndoorEnabled(bool)`, `setIndoorLevelPickerEnabled(bool)`
- `setMapId(String)` [Cloud styling]

## Markers
- `addMarker(MarkerOptions)`
- `updateMarker(id, {position, rotation})`
- `setMarkerIconBytes(id, bytes, {anchorU, anchorV})` [nativo]
- `removeMarker(id)` / `clearMarkers()`

```dart
await c.addMarker(MarkerOptions(
  id: 'driver:42',
  position: const LatLng(-23.56, -46.65),
  title: 'Motorista',
  iconUrl: 'https://meu.cdn.com/car.png',
  rotation: 15,
  zIndex: 1,
));
```

## Polylines
- `addPolyline(PolylineOptions)`
- `addPolylineFromEncoded(id, encoded, {color, width})`
- `updatePolylinePoints(id, points)`
- `removePolyline(id)` / `clearPolylines()`

```dart
await c.addPolyline(PolylineOptions(
  id: 'routeA',
  points: const [LatLng(-23.56, -46.65), LatLng(-23.57, -46.66)],
  color: Color(0xFF1976D2),
  width: 6,
));
```

## Overlays especiais (nativo)
- Heatmap: `setHeatmap(points, {radius, opacity})` / `clearHeatmap()`
- Tiles: `addTileOverlay(id, urlTemplate, {tileSize, opacity, zIndex})`, `removeTileOverlay(id)`, `clearTileOverlays()`

```dart
// Heatmap simples
await c.setHeatmap(const [
  LatLng(-23.561, -46.656),
  LatLng(-23.562, -46.657),
  LatLng(-23.563, -46.658),
], radius: 24, opacity: 0.7);

// Tiles XYZ (ex.: OpenTiles privada)
await c.addTileOverlay(
  'traffic_tiles',
  'https://tiles.exemplo.com/traffic/{z}/{x}/{y}.png',
  tileSize: 256,
  opacity: 0.9,
  zIndex: 1,
);
```

## Snapshot
- `Uint8List? takeSnapshot()` retorna PNG do viewport. [Web: não suportado]

## Ciclo de vida
- `dispose()` libera recursos da instância.

## Observações de plataforma
- Web: não há clustering/heatmap; `setMyLocationEnabled` é no-op; rotação de marker padrão não é suportada na JS API.
