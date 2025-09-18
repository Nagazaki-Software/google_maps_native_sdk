---
title: Markers
nav_order: 10
---

# Markers

Criação, atualização e remoção de marcadores.

## Adicionar marker
```dart
await controller.addMarker(MarkerOptions(
  id: 'driver:42',
  position: const LatLng(-23.56, -46.65),
  title: 'Motorista',
  snippet: 'Chegando em 2 min',
  iconUrl: 'https://cdn.exemplo.com/car.png', // http(s) ou asset://
  anchorU: 0.5, // 0..1
  anchorV: 0.62,
  rotation: 15,
  draggable: false,
  zIndex: 1,
));
```

## Atualizar posição/rotação
```dart
await controller.updateMarker('driver:42',
  position: const LatLng(-23.561, -46.651),
  rotation: 22,
);
```

## Ícone por bytes (nativo)
```dart
final bytes = await rootBundle.load('assets/pin.png')
  .then((b) => b.buffer.asUint8List());
await controller.setMarkerIconBytes('poi:1', bytes, anchorU: 0.5, anchorV: 1.0);
```

## Remover
```dart
await controller.removeMarker('driver:42');
await controller.clearMarkers();
```

## Eventos
```dart
controller.onMarkerTap.listen((id) {
  debugPrint('Marker tocado: $id');
});
```

Observações:
- Web (JS API) não oferece rotação para o marker padrão; use ícone customizado se precisar.
- Clustering: há `clusterEnabled` no widget (Android/iOS), indicado para muitos markers.

