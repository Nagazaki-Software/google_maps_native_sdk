ðŸš€ Google Maps Native SDK (Flutter/FlutterFlow)

- Nativo Android (Java) e iOS (Swift) + Flutter, com foco em mobilidade (ex.: tÃ¡xi): markers, polylines, cÃ¢mera, estilos, cache de Ã­cones, eventos e navegaÃ§Ã£o leve com voz. Bilingue (EN/PT-BR) abaixo.

**Highlights**
- ðŸ—ºï¸ PlatformView nativo (AndroidView / UiKitView)
- ðŸ“ Markers com Ã­cone por URL (cache memÃ³ria+disco), Ã¢ncora, rotaÃ§Ã£o e z-index
- âž¿ Polylines (lista de pontos ou polyline codificado) com update inâ€‘place
- ðŸŽ¥ CÃ¢mera: move/animate, fit bounds com padding
- ðŸŽ¨ Estilo: JSON ou tint por cor (`setMapColor`)
- ðŸš¦ Extras: trÃ¡fego, prÃ©dios, padding, snapshot
- ðŸ§­ Eventos: `onMarkerTap`, `onMapLoaded`
- ðŸŒ Web: mapa interativo com Google Maps JS (carregamento dinÃ¢mico)
- ðŸ§  Routes API v2 + Matriz de ETAs e TBT (voz)

**InstalaÃ§Ã£o RÃ¡pida**
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

**Uso BÃ¡sico**
```dart
GoogleMapController? controller;
GoogleMapView(
  initialCameraPosition: CameraPosition(target: LatLng(-23.56, -46.65), zoom: 13),
  trafficEnabled: true,
  onMapCreated: (c) async {
    controller = c;
    await c.onMapLoaded; // âœ… tiles & style prontos
    await c.addMarker(MarkerOptions(id: 'a', position: LatLng(-23.56, -46.65), title: 'Hello'));
  },
);
```

**Routes API (v2)**
- `RoutesApi.computeRoutes`: alternativas, route modifiers (evitar pedÃ¡gio/rodovia/balsa), waypoints avanÃ§ados (sideOfRoad/via), toll info, polyline quality, units/language, FieldMask
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

**NavegaÃ§Ã£o (TBT + Voz + Follow)**
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
session.onProgress.listen((p) {/* ETA e distÃ¢ncia restante */});
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
- AÃ§Ãµes prontas:
  - `await GmnsNavHub.computeRoutesAndDraw(...)`
  - `await GmnsNavHub.chooseActiveRoute(index)`
  - `await GmnsNavHub.startNavigation(...) / await GmnsNavHub.stopNavigation()`
  - `await GmnsNavHub.recenter()` / `await GmnsNavHub.overview()`
- Guia dedicado: `docs/FLUTTERFLOW_HELPERS.md`

**Scripts Ãšteis (cheat sheet)**
- ðŸ“¦ `flutter pub get` â€” instalar deps
- â–¶ï¸ `flutter run -d android` â€” rodar Android
- ðŸŽ `flutter run -d ios` â€” rodar iOS
- ðŸŒ `flutter config --enable-web` â€” habilitar Web
- ðŸ§ª `flutter run -d chrome` â€” rodar no Chrome
- ðŸ—ï¸ `flutter build web --release` â€” build Web
- ðŸ§¹ `flutter clean` â€” limpar cache de build

**Boas PrÃ¡ticas**
- ðŸ”‹ Use `onMapLoaded` antes de adicionar overlays pesados
- ðŸ â€œSnakeâ€ realtime: decime pontos + `updatePolylinePoints` (evite remover/adicionar a cada frame)
- ðŸ§± `setPadding` para nÃ£o encobrir UI (bottom sheet, etc.)
- ðŸš˜ `updateMarker` para mover o driver (suavize no Dart, se quiser)

**Notas / LimitaÃ§Ãµes**
- ðŸ”’ PermissÃµes de localizaÃ§Ã£o sÃ£o do app (ex.: `permission_handler`)
- ðŸ§© Clustering ainda nÃ£o exposto
- ðŸ“¡ Offline completo nÃ£o suportado (use cache do SDK + tiles custom)
- ðŸŒ Web: `setMyLocationEnabled` Ã© noâ€‘op; `takeSnapshot()` nÃ£o disponÃ­vel na JS API

**Exemplos**
- `example/lib/routes_tbt_demo.dart` â€” rotas alternativas, troca de rota, TBT + eventos
- Android Auto (referÃªncia): `example/android-auto-sample/README.md`

**FAQ**
- Web: erro `platformViewRegistry`
  - Atualize Flutter; este plugin usa o registro padrÃ£o de PlatformView no Web
- Conflito com pacote `web` (meu app Ã© sÃ³ iOS/Android)
  - O plugin nÃ£o exige `package:web` no mobile. Rode `flutter clean && flutter pub get`
- TTS nÃ£o fala
  - Verifique volume/Ã¡udio; em iOS configure AVAudioSession; ajuste `ttsRate/ttsPitch`

â€”
Made with â¤ï¸ for Lucas.
\n\nDocumentação: veja a pasta docs/ ou publique via GitHub Pages (Settings → Pages → Branch: main, Folder: /docs).\n
