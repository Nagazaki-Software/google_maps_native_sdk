---
title: Estilo
nav_order: 13
---

# Estilo do mapa

## JSON de estilo
```dart
const styleJson = '[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]}]';
await controller.setMapStyle(styleJson);
```

## Tinta por cor (helper)
```dart
final json = MapStyleBuilder.tinted(const Color(0xFF0D47A1), dark: false);
await controller.setMapStyle(json);
```

## Cloud Map ID
```dart
// Em Android, defina preferencialmente no widget via mapId; em iOS pode alterar em runtime
await controller.setMapId('SEU_MAP_ID');
```

Notas:
- Estilo por JSON é aplicado após o mapa carregar; combine com `onMapLoaded` para consistência.

