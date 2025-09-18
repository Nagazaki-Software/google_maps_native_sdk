Google Maps Native SDK (Flutter/FlutterFlow)

Plugin de mapas nativo para Flutter/FlutterFlow, com foco em apps de mobilidade. Inclui mapa nativo (Android/iOS), suporte Web via Google Maps JS, markers, polylines, controle de câmera, estilos, extras (tráfego, snapshot) e navegação leve com voz. Também oferece cliente para Routes API v2 e helpers para FlutterFlow.

Principais recursos
- Mapa nativo via PlatformView (AndroidView/UiKitView)
- Markers com ícone por URL/asset, âncora, rotação e z-index
- Polylines (lista de pontos ou polyline codificada) com atualização in-place
- Câmera: mover/animar, tilt/bearing, fit bounds com padding
- Estilo: JSON personalizado ou `setMapColor` (tinta por cor)
- Extras: tráfego, prédios, padding, snapshot (PNG)
- Eventos: `onMarkerTap`, `onMapLoaded`
- Web: Google Maps JS API com carregamento dinâmico
- Routes API v2 + Matriz de ETAs; Navegação TBT com voz (Directions API)

Instalação rápida
- Dependência:
  - `flutter pub add google_maps_native_sdk`
- Android (`AndroidManifest.xml`):
  - `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_ANDROID_API_KEY"/>`
- iOS (AppDelegate/Info.plist):
  - `GMSServices.provideAPIKey("YOUR_IOS_API_KEY")` ou entrada `GMSApiKey` no Info.plist
- Web:
  - `flutter config --enable-web`
  - Use `GoogleMapView(webApiKey: 'YOUR_WEB_MAPS_JS_API_KEY', ...)` ou adicione o script no `web/index.html`.

Uso básico
```dart
GoogleMapController? controller;

GoogleMapView(
  initialCameraPosition: const CameraPosition(
    target: LatLng(-23.56, -46.65),
    zoom: 13,
  ),
  trafficEnabled: true,
  onMapCreated: (c) async {
    controller = c;
    await c.onMapLoaded; // tiles + estilo prontos
    await c.addMarker(const MarkerOptions(
      id: 'a',
      position: LatLng(-23.56, -46.65),
      title: 'Olá',
    ));
  },
);
```

Routes API (v2)
```dart
final res = await RoutesApi.computeRoutes(
  apiKey: 'YOUR_ROUTES_API_KEY',
  origin: const Waypoint(location: LatLng(-23.561, -46.656)),
  destination: const Waypoint(location: LatLng(-23.570, -46.650)),
  intermediates: const [Waypoint(location: LatLng(-23.566, -46.653), via: true, sideOfRoad: true)],
  modifiers: const RouteModifiers(avoidHighways: true),
  alternatives: true,
  languageCode: 'pt-BR',
);
for (final r in res.routes) {
  await controller!.addPolyline(PolylineOptions(
    id: 'r${r.index}', points: r.points, color: const Color(0xFF1976D2), width: 6,
  ));
}
```

Navegação leve (TBT + voz)
```dart
final session = await MapNavigator.start(
  controller: controller!,
  options: const NavigationOptions(
    apiKey: 'YOUR_DIRECTIONS_API_KEY',
    origin: LatLng(-23.561, -46.656),
    destination: LatLng(-23.570, -46.650),
    language: 'pt-BR',
    voiceGuidance: true,
    cameraZoom: 17,
    cameraTilt: 45,
  ),
);

// Eventos da navegação
session.onProgress.listen((p) {/* ETA e distância restante */});
session.onInstruction.listen((i) {/* texto + manobra */});
session.onState.listen((s) {/* navigating/offRoute/rerouting */});
```

Flutter Web
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
    await c.addMarker(const MarkerOptions(id: 'w', position: LatLng(-23.56, -46.65)));
  },
)
```

FlutterFlow (helpers)
- Em `onMapCreated`: `GmnsNavHub.setController(controller)`
- Ações prontas:
  - `await GmnsNavHub.computeRoutesAndDraw(...)`
  - `await GmnsNavHub.chooseActiveRoute(index)`
  - `await GmnsNavHub.startNavigation(...) / await GmnsNavHub.stopNavigation()`
  - `await GmnsNavHub.recenter()` / `await GmnsNavHub.overview()`
- Guia dedicado: `docs/FLUTTERFLOW_HELPERS.md`

Boas práticas
- Aguarde `onMapLoaded` antes de adicionar muitos overlays
- Atualize polylines com `updatePolylinePoints` para rastro em tempo real
- Use `setPadding` para não encobrir UI (bottom sheet, barras)
- Para mover o “driver”, use `updateMarker` e suavize no Dart se necessário

Notas / Limitações
- Permissões de localização são responsabilidade do app
- Web: `setMyLocationEnabled` é no‑op; `takeSnapshot()` não é suportado pela JS API
- Clustering exposto apenas em Android/iOS (via `clusterEnabled` no widget)

Exemplos
- `example/lib/routes_tbt_demo.dart`: rotas alternativas, escolha de rota, TBT + eventos
- Android Auto (referência): `example/android-auto-sample/README.md`

Documentação
- Veja a pasta `docs/` para guias detalhados: Widget, Controller, Markers, Polylines, Câmera, Estilo, Web, Routes API, Navegação, FAQ e Troubleshooting.

