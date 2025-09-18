🚀 Google Maps Native SDK (Flutter/FlutterFlow)

- Nativo Android (Java) e iOS (Swift) + Flutter, com foco em mobilidade (ex.: táxi): markers, polylines, câmera, estilos, cache de ícones, eventos e navegação leve com voz. Bilingue (EN/PT-BR) abaixo.

**Highlights**
- 🗺️ PlatformView nativo (AndroidView / UiKitView)
- 📍 Markers com ícone por URL (cache memória+disco), âncora, rotação e z-index
- ➿ Polylines (lista de pontos ou polyline codificado) com update in‑place
- 🎥 Câmera: move/animate, fit bounds com padding
- 🎨 Estilo: JSON ou tint por cor (`setMapColor`)
- 🚦 Extras: tráfego, prédios, padding, snapshot
- 🧭 Eventos: `onMarkerTap`, `onMapLoaded`
- 🌐 Web: mapa interativo com Google Maps JS (carregamento dinâmico)
- 🧠 Routes API v2 + Matriz de ETAs e TBT (voz)

**Instalação Rápida**
- App Flutter
  - `flutter pub add google_maps_native_sdk`
  - Android (`AndroidManifest.xml`):
    - `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>`
  - iOS (AppDelegate ou Info.plist):
    - `GMSServices.provideAPIKey("YOUR_API_KEY")` ou `GMSApiKey` no Info.plist
  - Web
  - `flutter config --enable-web`
  - Use `GoogleMapView(webApiKey: 'YOUR_WEB_MAPS_JS_API_KEY', ...)` OU adicione em `web/index.html`:
    - `<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_MAPS_JS_API_KEY&libraries=geometry&v=weekly"></script>`

**Uso Básico**
```dart
GoogleMapController? controller;
GoogleMapView(
  initialCameraPosition: CameraPosition(target: LatLng(-23.56, -46.65), zoom: 13),
  trafficEnabled: true,
  onMapCreated: (c) async {
    controller = c;
    await c.onMapLoaded; // ✅ tiles & style prontos
    await c.addMarker(MarkerOptions(id: 'a', position: LatLng(-23.56, -46.65), title: 'Hello'));
  },
);
```

**Routes API (v2)**
- `RoutesApi.computeRoutes`: alternativas, route modifiers (evitar pedágio/rodovia/balsa), waypoints avançados (sideOfRoad/via), toll info, polyline quality, units/language, FieldMask
- `RoutesApi.computeRouteMatrix`: ETAs em lote
```dart
final res = await RoutesApi.computeRoutes(
  apiKey: 'YOUR_ROUTES_API_KEY',
  origin: Waypoint(location: LatLng(-23.561, -46.656)),
  destination: Waypoint(location: LatLng(-23.570, -46.650)),
  intermediates: [Waypoint(location: LatLng(-23.566, -46.653), via: true, sideOfRoad: true)],
  modifiers: const RouteModifiers(avoidHighways: true),
  alternatives: true,
  languageCode: 'pt-BR',
);
for (final r in res.routes) {
  await controller!.addPolyline(PolylineOptions(id: 'r${r.index}', points: r.points, color: const Color(0xFF1976D2)));
}
```

**Navegação (TBT + Voz + Follow)**
```dart
final session = await MapNavigator.start(
  controller: controller!,
  options: NavigationOptions(
    apiKey: 'YOUR_DIRECTIONS_API_KEY',
    origin: LatLng(-23.561, -46.656),
    destination: LatLng(-23.570, -46.650),
    language: 'pt-BR', voiceGuidance: true, ttsRate: 0.95,
  ),
);
// Alimente sua UI:
session.onProgress.listen((p) {/* ETA e distância restante */});
session.onInstruction.listen((i) {/* texto + manobra */});
session.onState.listen((s) {/* navigating/offRoute/rerouting */});
```

**Flutter Web**
```dart
GoogleMapView(
  webApiKey: 'YOUR_WEB_MAPS_JS_API_KEY', // ou script manual em web/index.html
  initialCameraPosition: CameraPosition(
    target: LatLng(-23.56, -46.65),
    zoom: 13,
    tilt: 30, // novo
    bearing: 120, // novo
  ),
  onMapCreated: (c) async {
    await c.onMapLoaded;
    await c.addMarker(MarkerOptions(id: 'w', position: LatLng(-23.56, -46.65)));
  },
)
```

**FlutterFlow (Helpers)**
- Em `onMapCreated`: `GmnsNavHub.setController(controller)`
- Ações prontas:
  - `await GmnsNavHub.computeRoutesAndDraw(...)`
  - `await GmnsNavHub.chooseActiveRoute(index)`
  - `await GmnsNavHub.startNavigation(...) / await GmnsNavHub.stopNavigation()`
  - `await GmnsNavHub.recenter()` / `await GmnsNavHub.overview()`
- Guia dedicado: `docs/FLUTTERFLOW_HELPERS.md`

**Scripts Úteis (cheat sheet)**
- 📦 `flutter pub get` — instalar deps
- ▶️ `flutter run -d android` — rodar Android
- 🍎 `flutter run -d ios` — rodar iOS
- 🌐 `flutter config --enable-web` — habilitar Web
- 🧪 `flutter run -d chrome` — rodar no Chrome
- 🏗️ `flutter build web --release` — build Web
- 🧹 `flutter clean` — limpar cache de build

**Boas Práticas**
- 🔋 Use `onMapLoaded` antes de adicionar overlays pesados
- 🐍 “Snake” realtime: decime pontos + `updatePolylinePoints` (evite remover/adicionar a cada frame)
- 🧱 `setPadding` para não encobrir UI (bottom sheet, etc.)
- 🚘 `updateMarker` para mover o driver (suavize no Dart, se quiser)

**Notas / Limitações**
- 🔒 Permissões de localização são do app (ex.: `permission_handler`)
- 🧩 Clustering ainda não exposto
- 📡 Offline completo não suportado (use cache do SDK + tiles custom)
- 🌐 Web: `setMyLocationEnabled` é no‑op; `takeSnapshot()` não disponível na JS API

**Exemplos**
- `example/lib/routes_tbt_demo.dart` — rotas alternativas, troca de rota, TBT + eventos
- Android Auto (referência): `example/android-auto-sample/README.md`

**FAQ**
- Web: erro `platformViewRegistry`
  - Atualize Flutter; este plugin usa o registro padrão de PlatformView no Web
- Conflito com pacote `web` (meu app é só iOS/Android)
  - O plugin não exige `package:web` no mobile. Rode `flutter clean && flutter pub get`
- TTS não fala
  - Verifique volume/áudio; em iOS configure AVAudioSession; ajuste `ttsRate/ttsPitch`

—
Made with ❤️ for Lucas.
