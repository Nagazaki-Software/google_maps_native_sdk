What's New

- Android/iOS: Added `GoogleMapController.setMarkerIconBytes(id, bytes, {anchorU, anchorV})` to update a marker icon from raw PNG/JPEG bytes. Useful for Firebase Storage or authenticated URLs where passing a direct URL is not feasible.
- All platforms: `GoogleMapController.updatePolylinePoints(id, points)` updates existing polylines in place for smoother real-time paths.

Notes

- On Web, `setMarkerIconBytes` is currently a no-op. You can still set marker icons using URLs via `MarkerOptions.iconUrl`.
- For high-frequency camera and polyline updates, prefer `animateCamera` with a duration and throttle `updatePolylinePoints` to ~10–20 Hz to avoid MethodChannel overhead.
