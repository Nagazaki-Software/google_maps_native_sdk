---
title: Flutter Web
nav_order: 5
---

# Web (Google Maps JS)

No Web, o plugin cria um `HtmlElementView` e carrega a Google Maps JavaScript API automaticamente quando você passa `webApiKey` no `GoogleMapView`. Alternativamente, injete o `<script>` manualmente no `web/index.html`.

## Exemplo
```dart
GoogleMapView(
  webApiKey: 'YOUR_WEB_MAPS_JS_API_KEY',
  initialCameraPosition: const CameraPosition(
    target: LatLng(-23.56, -46.65),
    zoom: 13,
    tilt: 30,
    bearing: 120,
  ),
  onMapCreated: (c) async {
    await c.onMapLoaded;
    await c.addMarker(MarkerOptions(id: 'w', position: const LatLng(-23.56, -46.65)));
  },
)
```

## Limitações atuais
- `takeSnapshot()` retorna `null` (JS API não expõe captura nativa)
- `setMyLocationEnabled` é no‑op
- Rotação de marker padrão não é suportada (use ícones personalizado/AdvancedMarker se necessário)
- Clustering/Heatmap não expostos no Web host

