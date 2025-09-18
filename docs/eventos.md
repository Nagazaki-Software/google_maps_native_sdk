---
title: Eventos
nav_order: 14
---

# Eventos & Lifecycle

## Mapa carregado
```dart
await controller.onMapLoaded; // tiles + estilo prontos
```

## Toque em marker
```dart
controller.onMarkerTap.listen((id) {
  // Abrir bottom sheet, destacar rota, etc.
});
```

## Liberação de recursos
```dart
await controller.dispose();
```

Recomendações:
- Aguarde `onMapLoaded` antes de adicionar muitos overlays ou estilizar.
- Sempre descarte (`dispose`) controladores quando a tela for destruída.

