---
title: Visão Geral
nav_order: 1
---

# Google Maps Native SDK (Flutter/FlutterFlow)

Plugin de mapas nativo para Flutter com foco em apps de mobilidade (Android/iOS e Web). Fornece o widget `GoogleMapView`, o `GoogleMapController` para interagir (markers, polylines, câmera, estilo, snapshots), navegação leve Turn‑by‑Turn com voz (Directions API) e cliente para Routes API v2 (alternativas, toll, matriz de ETAs).

- Nativo Android (Java/Kotlin) e iOS (Swift) via PlatformViews
- Web com Google Maps JavaScript API (carregamento dinâmico)
- Eventos: `onMarkerTap`, `onMapLoaded`
- Extras: snapshot, padding, estilo por JSON, `setMapColor`

Veja o exemplo completo em `example/` e as páginas abaixo com guias e códigos prontos.

## Instalação Rápida

1) Dependência
```
flutter pub add google_maps_native_sdk
```

2) Chave de API Google Maps
- Android: adicione em `android/app/src/main/AndroidManifest.xml`:
```
<application>
  <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_ANDROID_API_KEY"/>
</application>
```

- iOS: configure no `AppDelegate` ou Info.plist (GMSApiKey)
```
GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
```

- Web: passe `webApiKey` no `GoogleMapView` OU injete o script no `web/index.html`:
```
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_MAPS_JS_API_KEY&libraries=geometry&v=weekly"></script>
```

3) Primeiro mapa
```dart
GoogleMapController? controller;

GoogleMapView(
  initialCameraPosition: CameraPosition(
    target: LatLng(-23.56, -46.65),
    zoom: 13,
  ),
  trafficEnabled: true,
  onMapCreated: (c) async {
    controller = c;
    await c.onMapLoaded; // tiles + estilo prontos
    await c.addMarker(MarkerOptions(
      id: 'a',
      position: LatLng(-23.56, -46.65),
      title: 'Olá',
    ));
  },
);
```

Próximo passo: leia `Widget` e `Controller` para conhecer todas as funcionalidades.

