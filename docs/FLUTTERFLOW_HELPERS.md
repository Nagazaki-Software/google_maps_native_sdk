---
title: FlutterFlow Helpers
nav_order: 20
---

FlutterFlow Helpers (Actions)

Overview
- This package exposes a simple static hub `GmnsNavHub` to simplify wiring in FlutterFlow custom actions.
- You can create custom actions in FlutterFlow that call the methods below via a wrapper Dart file in your app.

Quick API
- Set controller once (on map created):
  GmnsNavHub.setController(controller);
- Compute + draw routes (alternatives):
  await GmnsNavHub.computeRoutesAndDraw(apiKey: 'KEY', origin: LatLng(...), destination: LatLng(...));
- Choose active route:
  await GmnsNavHub.chooseActiveRoute(0);
- Start/Stop navigation:
  await GmnsNavHub.startNavigation(apiKey: 'KEY', origin: LatLng(...), destination: LatLng(...));
  await GmnsNavHub.stopNavigation();
- Recenter/Overview during navigation:
  await GmnsNavHub.recenter();
  await GmnsNavHub.overview();

Binding in FlutterFlow
1) Add this package as a custom package.
2) In your page with the map widget, expose `onMapCreated` and store the controller instance to call:
   GmnsNavHub.setController(controller);
3) Create Custom Actions that call the methods above (wrap them in your app code if needed).
4) Use the Events stream (ETA, instruction) by listening in your app code and exposing as state (e.g., using a `StreamProvider`) — or poll via callbacks.

Notes
- The hub stores a single controller/session reference. If your app uses multiple maps, extend the hub to manage multiple IDs.
- For dynamic speed limit/lanes/incidents, integrate additional Google APIs and forward to your UI as needed.
