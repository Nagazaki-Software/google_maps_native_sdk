**Google Maps Native SDK (Flutter/FlutterFlow)**

- Native Google Maps plugin (Android Java / iOS Swift) for Flutter, built for mobility apps (e.g., taxi): markers, polylines, events, snapshot and icon caching. Bilingual docs (English/Português) below.

**Features**
- Native PlatformView (`AndroidView` / `UiKitView`).
- Markers with icon by URL (memory + disk cache), anchor, rotation and z-index.
- Polylines (points list or encoded polyline via `addPolylineFromEncoded`).
- Camera: move/animate, fit bounds with padding.
- Map styling: JSON style or single-color tint via `setMapColor(Color, {dark: false})`.
- Extras: traffic, buildings, map padding, snapshot.
- Events: marker tap (`onMarkerTap` stream).

**Install**
- Add dependency in your app `pubspec.yaml` (path/git or Pub when published).
- Android: add your Google Maps API Key in the app `AndroidManifest.xml`:
  - `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>`
- iOS: provide the API key in `AppDelegate` or Info.plist:
  - `GMSServices.provideAPIKey("YOUR_API_KEY")` or `GMSApiKey` in Info.plist.

**Quick Start** (see `example/lib/main.dart`)
- Widget: `GoogleMapView(initialCameraPosition: CameraPosition(target: LatLng(-23.56,-46.65), zoom: 13), onMapCreated: ...)`.
- Controller: `addMarker(...)`, `addPolyline(...)`, `moveCamera(...)`, `animateToBounds(...)`, `setMapStyle(...)`, `setMapColor(...)`, `takeSnapshot()`.

**FlutterFlow**
- Import as Custom Package and use `GoogleMapView`. Use `onMapCreated` to wire controller calls via custom actions.

**Best practices (mobility/taxi)**
- Enable `trafficEnabled` when useful to reduce visual noise.
- Use `setPadding` to accommodate panels (e.g., bottom sheet).
- Update driver position with `updateMarker` (optionally smooth in Dart first).
- Use URL marker icons; built-in memory+disk cache reduces flicker and network.

**Notes / Limitations**
- Location permissions are app responsibility (e.g., `permission_handler`).
- Clustering is not exposed yet (native Utils libs are included for future work).
- Full offline tiles are not supported; use SDK cache + custom tiles if needed.

—

**Google Maps Native SDK (Flutter/FlutterFlow) — Português**

- Plugin Flutter com views nativas (Android Java / iOS Swift) do Google Maps, focado em apps de mobilidade (ex.: táxi): markers, polylines, eventos, snapshot e cache de ícones (memória + disco). Documentação bilíngue.

**Recursos**
- PlatformView nativo (`AndroidView` / `UiKitView`).
- Markers com ícone por URL (cache memória + disco), âncora, rotação e z-index.
- Polylines (lista de pontos ou polyline codificado via `addPolylineFromEncoded`).
- Câmera: mover/animar, bounds com padding.
- Estilização: JSON ou cor única com `setMapColor(Color, {dark: false})`.
- Extras: tráfego, prédios, padding do mapa, snapshot.
- Eventos: toque em marker (`onMarkerTap`).

**Instalação**
- Adicione no `pubspec.yaml` do app (path/git ou Pub quando publicado).
- Android: adicione a API Key no `AndroidManifest.xml` do app.
- iOS: forneça a API Key no `AppDelegate` ou Info.plist.

**Uso Rápido**
- Widget e controller conforme exemplo em `example/lib/main.dart`.
- Chaves principais: `addMarker`, `addPolyline`, `moveCamera`, `animateToBounds`, `setMapStyle`, `setMapColor`, `takeSnapshot`.

**FlutterFlow**
- Importe como Custom Package e use `GoogleMapView` com `onMapCreated` para acionar o controller por ações custom.

**Boas práticas**
- Habilite `trafficEnabled` quando útil.
- Use `setPadding` para acomodar overlays.
- Atualize posição do motorista com `updateMarker`.
- Ícones por URL com cache (memória + disco) integrado.

**Limitações**
- Permissões de localização são do app.
- Clustering: previsto para próxima versão.

