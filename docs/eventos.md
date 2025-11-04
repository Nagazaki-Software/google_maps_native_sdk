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

Ou, mais simples, use o callback do widget (com acesso direto ao BuildContext):

```dart
GoogleMapView(
  initialCameraPosition: CameraPosition(
    target: const LatLng(-23.56, -46.65),
    zoom: 14,
  ),
  onMarkerTap: (context, markerId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => MeuComponente(markerId: markerId),
    );
  },
)
```

## Liberação de recursos
```dart
await controller.dispose();
```

Recomendações:
- Aguarde `onMapLoaded` antes de adicionar muitos overlays ou estilizar.
- Sempre descarte (`dispose`) controladores quando a tela for destruída.
