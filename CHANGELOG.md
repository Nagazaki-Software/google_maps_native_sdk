# Changelog

## 0.7.0

EN
- Navigation SDK (Turn‑by‑Turn): voice guidance with multi‑threshold announcements, snapping to route, arrival detection, pause/resume, simulation, and rerouting.
  - New NavigationOptions: `approachSpeakMeters`, `arrivalThresholdMeters`, `snapToRoute`, `mapMatchingToleranceMeters`, `rerouteOnOffRoute`, `simulationSpeedKmh`, `speedAlertsEnabled`, `speedLimitKmh`, `speedLimitProvider`, `useRoutesV2`, `intermediates`.
  - New session controls: `pause()`, `resume()`, `isSimulating`, `setSimulationSpeed(kmh)`.
  - New states in `onState`: `navigating`, `offRoute`, `rerouting`, `paused`, `arrived`.
  - Uses classic Directions by default; optionally uses Routes API v2 steps when `useRoutesV2: true`.
- Routes API v2 client: extended FieldMask and types.
  - RouteData now includes `northeast/southwest` viewport, `routeLabels`, `staticDurationSeconds`, and `legs`.
  - New `RouteLegData` and `RouteStepData` with per‑step polyline, distance, instruction and maneuver.
- UI: added `NavInstructionBanner` widget to display maneuver icon, instruction text and remaining distance.
- FlutterFlow helpers: `startNavigation` now accepts `useRoutesV2` and `intermediates`.
- Docs: updated Navigation (options, states, simulation), Routes API v2 (viewport/steps), and added UI banner guide.
- Misc: analyzer fixes, color API deprecation addressed, helper bounds functions.

PT‑BR
- SDK de Navegação (Turn‑by‑Turn): voz com múltiplos limiares, snapping na rota, detecção de chegada, pausar/retomar, simulação e reroteamento.
  - Novos NavigationOptions: `approachSpeakMeters`, `arrivalThresholdMeters`, `snapToRoute`, `mapMatchingToleranceMeters`, `rerouteOnOffRoute`, `simulationSpeedKmh`, `speedAlertsEnabled`, `speedLimitKmh`, `speedLimitProvider`, `useRoutesV2`, `intermediates`.
  - Novos controles da sessão: `pause()`, `resume()`, `isSimulating`, `setSimulationSpeed(kmh)`.
  - Novos estados em `onState`: `navigating`, `offRoute`, `rerouting`, `paused`, `arrived`.
  - Padrão usa Directions; opcionalmente usa Steps do Routes API v2 com `useRoutesV2: true`.
- Cliente Routes API v2: FieldMask ampliada e novos tipos.
  - RouteData agora inclui viewport (`northeast/southwest`), `routeLabels`, `staticDurationSeconds` e `legs`.
  - Novos `RouteLegData` e `RouteStepData` com polyline do passo, distância, instrução e maneuver.
- UI: novo widget `NavInstructionBanner` para mostrar manobra, texto e distância.
- FlutterFlow helpers: `startNavigation` aceita `useRoutesV2` e `intermediates`.
- Docs: Navegação (opções, estados, simulação), Routes API v2 (viewport/steps) e guia do banner de instruções.
- Miscelânea: correções de analyzer, ajuste de API de cor, funções auxiliares de bounds.

## 0.6.8

EN
- Documentation overhaul: added a docs site structure (Just the Docs theme) with guides for installation, widget, controller, web, markers, polylines, camera, style, events, FAQ, troubleshooting and scripts.
- README reworked for clarity (Portuguese) and links to the docs.
- No breaking API changes.

PT‑BR
- Reformulação de documentação: site em `docs/` com guias de instalação, widget, controller, web, markers, polylines, câmera, estilo, eventos, FAQ, troubleshooting e scripts.
- README reescrito com foco e links para as docs.
- Sem mudanças de API que quebrem compatibilidade.

## 0.6.5

EN
- Clustering: Android via ClusterManager and iOS via GMUClusterManager with custom renderer; preserves iconUrl, anchor, rotation, zIndex, draggable. Opt-in via `GoogleMapView(clusterEnabled: true)` or `setClusteringEnabled(true)`.
- Heatmaps: Android (HeatmapTileProvider) and iOS (GMUHeatmapTileLayer). New methods: `heatmap#set`, `heatmap#clear`.
- Tile overlays: URL template tiles with add/remove/clear. Android (UrlTileProvider + TileOverlay), iOS (GMSTileLayer).
- Lite mode (Android): `GoogleMapView(liteMode: true)` for mini-maps/lists.
- Indoors: `indoorEnabled` and Android UI `indoorLevelPicker`; controller setters provided.
- Cloud styling (Map ID): `mapId` in widget. iOS supports runtime `setMapId`; Android requires MapId at creation and returns error if set at runtime.
- Camera: tilt/bearing in CameraPosition and moveCamera; animateCamera duration honored on iOS (CATransaction) and Web (rAF interpolation).
- Web: dynamic JS loader uses `importLibrary('maps')` when available; initial options honor tilt and heading; smoother animations.

PT-BR
- Clustering: Android com ClusterManager e iOS com GMUClusterManager (renderer custom); preserva iconUrl, anchor, rotation, zIndex, draggable. Ative com `GoogleMapView(clusterEnabled: true)` ou `setClusteringEnabled(true)`.
- Heatmaps: Android (HeatmapTileProvider) e iOS (GMUHeatmapTileLayer). Métodos: `heatmap#set`, `heatmap#clear`.
- Tile overlays: tiles por template de URL com add/remove/clear. Android (UrlTileProvider + TileOverlay), iOS (GMSTileLayer).
- Lite mode (Android): `GoogleMapView(liteMode: true)` para mini-mapas/listas.
- Indoor: `indoorEnabled` e `indoorLevelPicker` (controle de UI no Android); setters no controller.
- Estilo Cloud (Map ID): `mapId` no widget. iOS suporta `setMapId` em runtime; Android exige no creation e retorna erro ao tentar em runtime.
- Câmera: tilt/bearing no CameraPosition e moveCamera; animateCamera respeita duração no iOS (CATransaction) e Web (interp. rAF).
- Web: loader dinâmico usa `importLibrary('maps')` quando disponível; opções iniciais respeitam tilt/heading; animações mais suaves.

## 0.6.1

EN
- Camera: add tilt and bearing to CameraPosition and moveCamera; animateCamera supports custom duration on iOS (CATransaction) and Web (requestAnimationFrame interpolation). Android already supports duration.
- Web: animate center/zoom/tilt/bearing when durationMs is provided; initial MapOptions now honor tilt and heading.

PT-BR
- Câmera: suporte a tilt e bearing em CameraPosition e moveCamera; animateCamera com duração custom no iOS (CATransaction) e Web (interp. via requestAnimationFrame). Android já aceitava duração.
- Web: anima centro/zoom/tilt/bearing quando durationMs é fornecido; MapOptions inicial agora respeita tilt e heading.

## 0.5.10

EN
- iOS: fix Google Maps iOS SDK API changes. Replaced `mapView.buildingsEnabled` with `mapView.isBuildingsEnabled`.
- iOS: fix Swift type mismatch in camera animation. `tilt` now remains `Double` to match `GMSCameraPosition(viewingAngle:)`.
- iOS: fix Swift initializer order for `iconDiskCacheURL` (initialize before `super.init`). Prevents "Immutable value ... may only be initialized once" and "Property not initialized at super.init" errors during archive.

PT-BR
- iOS: correção da API do Google Maps iOS SDK. Substituído `mapView.buildingsEnabled` por `mapView.isBuildingsEnabled`.
- iOS: correção de tipo no Swift durante animação de câmera. `tilt` permanece `Double` para o `viewingAngle` do `GMSCameraPosition`.
- iOS: correção da ordem no inicializador para `iconDiskCacheURL` (inicializa antes de `super.init`). Evita erros de build no archive.

## 0.5.8

EN
- Web: fixed platform view registration using `ui.platformViewRegistry.registerViewFactory` for wider Flutter compatibility.
- Web: removed `dart:html` usage from the web registrar; `getPlatformVersion()` now returns a stable 'web' string to avoid deprecation warnings.
- Web: no hard dependency on `package:web` for mobile-only apps; only `flutter_web_plugins` is referenced during web builds.
- Web: improved polyline color encoding (helper) and minor cleanups (`const HtmlElementView`, removed unused class).
- Example: addressed `use_build_context_synchronously` in `routes_tbt_demo.dart`.
- Docs: README clarified Web setup and options (auto script vs manual script tag).

PT-BR
- Web: correção no registro da view com `ui.platformViewRegistry.registerViewFactory` para compatibilidade ampla com Flutter.
- Web: remoção de `dart:html` no registrador; `getPlatformVersion()` retorna 'web' para evitar avisos de depreciação.
- Web: sem dependência rígida de `package:web` em apps só iOS/Android; apenas `flutter_web_plugins` é usado em builds Web.
- Web: melhoria no encoding de cor da polyline e ajustes menores (`HtmlElementView` `const`, remoção de classe não utilizada).
- Exemplo: ajuste do `use_build_context_synchronously` em `routes_tbt_demo.dart`.
- Docs: README com passos Web mais claros (carregamento automático vs `<script>` manual).

## 0.4.4

EN
- Routes API: new `RoutesApi` client (v2) with `computeRoutes` (alternatives, route modifiers: avoid tolls/highways/ferries; advanced waypoints: sideOfRoad + via/stopover; toll info; polyline quality; units/language; configurable `X-Goog-FieldMask`) and `computeRouteMatrix` (batch ETAs for multiple origins/destinations).
- Navigation events: `NavigationSession` now exposes `onState` (navigating/offRoute/rerouting), `onInstruction` (step text + maneuver + distance), `onProgress` (distance remaining + ETA), and `onSpeedAlert` (simple speed monitor with optional static limit). TTS now supports rate/pitch/voice.
- Camera helpers: `NavigationSession.recenter()`/`overview()` utilities. Follow-me remains with tilt/bearing smoothing via `animateCamera`.
- Docs: README updated with Routes API usage, event streams, and notes for FlutterFlow actions.
- Sample: new `example/lib/routes_tbt_demo.dart` (Routes + TBT). Android Auto reference at `example/android-auto-sample/`.

PT-BR
- Routes API: novo cliente `RoutesApi` (v2) com `computeRoutes` (alternativas, modificadores de rota: evitar pedágios/rodovias/balsas; waypoints avançados: sideOfRoad + via/stopover; info de pedágio; qualidade da polyline; unidades/idioma; `X-Goog-FieldMask` configurável) e `computeRouteMatrix` (ETAs em lote para múltiplas origens/destinos).
- Eventos de navegação: `NavigationSession` expõe `onState` (navigating/offRoute/rerouting), `onInstruction` (texto + manobra + distância), `onProgress` (distância restante + ETA) e `onSpeedAlert` (velocímetro simples com limite estático opcional). TTS com rate/pitch/voice.
- Câmera: utilitários `recenter()`/`overview()`. Follow-me segue com tilt/bearing suave via `animateCamera`.
- Docs: README atualizado com uso do Routes API, event streams e dicas para FlutterFlow.
- Sample: `example/lib/routes_tbt_demo.dart` (Rotas + TBT). Exemplo de referência Android Auto em `example/android-auto-sample/`.


## 0.4.0
EN

- Routes API: new RoutesApi client (v2) with computeRoutes (alternatives, route modifiers: avoid tolls/highways/ferries; advanced waypoints: sideOfRoad + via/stopover; toll info; polyline quality; units/language; configurable X-Goog-FieldMask) and computeRouteMatrix (batch ETAs for multiple origins/destinations).
- Navigation events: NavigationSession now exposes onState (navigating/offRoute/rerouting), onInstruction (step text + maneuver + distance), onProgress (distance remaining + ETA), and onSpeedAlert (simple speed monitor with optional static limit). TTS now supports rate/pitch/voice.
- Camera helpers: NavigationSession.recenter()/overview() utilities. Follow-me remains with tilt/bearing smoothing via animateCamera.
- Docs: README updated with Routes API usage, event streams, and notes for FlutterFlow actions.

PT-BR
- Routes API: novo cliente RoutesApi (v2) com computeRoutes (alternativas, modificadores de rota: evitar pedágios/rodovias/balsas; waypoints avançados: sideOfRoad + via/stopover; info de pedágio; qualidade da polyline; unidades/idioma; X-Goog-FieldMask configurável) e computeRouteMatrix (ETAs em lote para múltiplas origens/destinos).
- Eventos de navegação: NavigationSession expõe onState (navigating/offRoute/rerouting), onInstruction (texto + manobra + distância), onProgress (distância restante + ETA) e onSpeedAlert (velocímetro simples com limite estático opcional). TTS com rate/pitch/voice.
- Câmera: utilitários recenter()/overview(). Follow-me segue com tilt/bearing suave via animateCamera.
- Docs: README atualizado com uso do Routes API, event streams e dicas para FlutterFlow.

## 0.3.0

EN
- Android: MapView receives full host lifecycle (start/resume/pause/stop/destroy). Map is revealed only after OnMapLoadedCallback; emits `event#onMapLoaded` (exposed in Dart as `onMapLoaded`).
- iOS: Reveal map only after content is ready (snapshotReady), also emits `event#onMapLoaded`.
- iOS: Update polyline in place by changing `GMSPolyline.path` (no recreation). New channel method `polylines#updatePoints`.
- Android: Update polyline points in place via `Polyline.setPoints(...)`. New channel method `polylines#updatePoints`.
- Dart API: Added `updatePolylinePoints(String id, List<LatLng>)` and `onMapLoaded` future in `GoogleMapController`.
- Markers: URL icons decoded off-main-thread and resized to ~48dp; default anchor is now (u=0.5, v=0.62).
- Static map: Added `StaticMapView` (Google Static Maps) with optional polyline, useful for Windows/desktop fallback.
- Docs: README expanded with examples (onMapLoaded, updatePolylinePoints, static map, and best practices for high-frequency polyline updates – "snake": decimation + 16–32ms throttle without remove/add each frame).

PT-BR (ASCII)
- Android: MapView agora recebe todos os lifecycles do host. Mapa aparece somente apos OnMapLoadedCallback; emite `event#onMapLoaded` (Dart: `onMapLoaded`).
- iOS: Revela o mapa apenas quando pronto (snapshotReady), tambem emite `event#onMapLoaded`.
- iOS: Atualiza `GMSPolyline.path` sem recriar. Novo metodo `polylines#updatePoints`.
- Android: Atualiza pontos da polyline em lugar (`Polyline.setPoints`). Novo metodo `polylines#updatePoints`.
- Dart: `updatePolylinePoints(String id, List<LatLng>)` e `onMapLoaded` no `GoogleMapController`.
- Markers: icones por URL decodificados fora da main-thread e redimensionados (~48dp). Ancora padrao agora (0.5, 0.62).
- Mapa estatico: novo `StaticMapView` com polyline (Google Static Maps), util no Windows/desktop.
- Docs: README ampliado com exemplos e dicas de "snake" (decimacao + throttle 16–32ms, sem remover/adicionar a cada frame).

## 0.2.0

EN
- Navigation (Directions + Voice + Follow): new Dart helper with `MapNavigator.start(...)` and `NavigationOptions` to fetch a Google Directions route, draw the polyline, follow the user with the camera, and speak step instructions (TTS). Includes simple re-route when off-route.
- Camera: new `animateCamera(target, {zoom, tilt, bearing, durationMs})` method in `GoogleMapController` (native Android/iOS updated).
- Docs: README updated with navigation usage.
- Dependencies: added `http`, `geolocator`, `flutter_tts` (the app remains responsible for location permissions).

PT-BR
- Navegação (Rotas + Voz + Follow): novo helper em Dart com `MapNavigator.start(...)` e `NavigationOptions` para buscar rota (Google Directions), desenhar a polyline, seguir a localização do usuário com a câmera e falar as instruções (TTS). Inclui re-roteamento simples ao sair da rota.
- Câmera: novo método `animateCamera(target, {zoom, tilt, bearing, durationMs})` no `GoogleMapController` (Android/iOS nativos atualizados).
- Docs: README atualizado com uso de navegação.
- Dependências: adicionadas `http`, `geolocator`, `flutter_tts` (o app continua responsável por permissões de localização).

## 0.1.0

EN
- First release of the plugin.
- `GoogleMapView` widget with `AndroidView` / `UiKitView`.
- `GoogleMapController` with: markers (add/update/remove/clear), polylines (add/remove/clear), camera (move/fit bounds), map style, traffic, myLocation, padding, snapshot.
- Icon cache: LRU (Android) and NSCache (iOS) with async download.
- Functional example (`example/`) simulating a ride flow (pickup/dropoff/route/driver).

PT-BR
- Primeira versão do plugin.
- Widget `GoogleMapView` com `AndroidView`/`UiKitView`.
- `GoogleMapController` com: markers (add/update/remove/clear), polylines (add/remove/clear), câmera (move/fit bounds), estilo de mapa, tráfego, myLocation, padding, snapshot.
- Cache de ícones: LRU (Android) e NSCache (iOS), com download assíncrono.
- Exemplo funcional (`example/`) simulando fluxo de corrida (pickup/dropoff/rota/driver).
## 0.5.0

EN
- Web: interactive map for Flutter Web using Google Maps JavaScript API, loaded dynamically (optional manual script). Supports markers, polylines (update in place), camera controls, style (JSON tint), traffic layer, and events (marker tap, map loaded). Caching via browser (tiles/icons) and in-memory reuse by ids.
- API: `GoogleMapView` adds `webApiKey` (optional) to auto-load JS. Controller adapts transparently on Web.
- Docs: README expanded with Web setup and code sample. No change required in native platforms.

PT-BR
- Web: mapa interativo no Flutter Web usando a Google Maps JavaScript API (carregamento dinâmico; ou script manual). Suporte a markers, polylines (atualização in-place), câmera, estilo (JSON/tint), camada de tráfego e eventos (toque em marker, mapa pronto). Cache via navegador (tiles/ícones) e reuso em memória por ids.
- API: `GoogleMapView` ganhou `webApiKey` (opcional) para carregar a JS API automaticamente. Controller funciona de forma transparente no Web.
- Docs: README com guia de Web e exemplo de código. Nenhuma mudança no Android/iOS.
