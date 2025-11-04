What's New

- Android/iOS: Added `GoogleMapController.setMarkerIconBytes(id, bytes, {anchorU, anchorV})` to update a marker icon from raw PNG/JPEG bytes. Useful for Firebase Storage or authenticated URLs where passing a direct URL is not feasible.
- All platforms: `GoogleMapController.updatePolylinePoints(id, points)` updates existing polylines in place for smoother real-time paths.

Notes

- On Web, `setMarkerIconBytes` is currently a no-op. You can still set marker icons using URLs via `MarkerOptions.iconUrl`.
- For high-frequency camera and polyline updates, prefer `animateCamera` with a duration and throttle `updatePolylinePoints` to ~10–20 Hz to avoid MethodChannel overhead.
---
title: What's New
nav_order: 99
---

- Navigation UI bridge (Android/iOS): new `NavigationUi.start/stop/isAvailable` to open native Google Navigation UI (when SDK present) with route + theme + language; placeholder fallback otherwise.
- Android Auto scaffold: minimal `CarAppService` + `Session`/`Screen` to help you wire `androidx.car.app` Navigation templates.
- CarPlay scaffold: Swift helper `GMNSCarPlayManager.makeRootTemplate()` to kickstart a CarPlay extension (templates Apple).
- TBT theming + vehicle marker: `NavigationOptions.routeColor`/`routeWidth` and configurable vehicle marker (`vehicleIconUrl`, `vehicleIconDp`, anchors, rotation source).
- Marker icons: `MarkerOptions.iconDp` to control native icon size scaling with caching on Android/iOS.
 - Super cache improvements:
   - Android: memory+disk cache keyed by `url#dp=<size>` (evita reescala em cadeia e artefatos). Cache em disco com limpeza LRU (~32MB ou 300 arquivos).
   - iOS: cache em disco também com limpeza LRU (~32MB ou 300 arquivos) e chave `url#dp`.
   - Web: usa cache do navegador; sem mudanças.
