package com.example.google_maps_native_sdk;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.util.LruCache;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.PolylineOptions;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

// Clustering & heatmap & tiles
import com.google.maps.android.clustering.ClusterManager;
import com.google.maps.android.clustering.ClusterItem;
import com.google.maps.android.heatmaps.HeatmapTileProvider;
import com.google.android.gms.maps.model.TileOverlay;
import com.google.android.gms.maps.model.TileOverlayOptions;
import com.google.android.gms.maps.model.UrlTileProvider;

class MapViewPlatformView implements PlatformView, OnMapReadyCallback, MethodCallHandler, GoogleMap.OnMarkerClickListener {
  private final Context context;
  private final MapView mapView;
  private GoogleMap map;
  private final MethodChannel channel;
  private final LruCache<String, Bitmap> iconCache;
  private final ExecutorService executor = Executors.newCachedThreadPool();
  private final java.io.File diskCacheDir;

  private final Map<String, Marker> markers = new HashMap<>();
  private final Map<String, com.google.android.gms.maps.model.Polyline> polylines = new HashMap<>();
  private final Map<String, TileOverlay> tileOverlays = new HashMap<>();
  private final Map<String, ClusterItemImpl> clusterItems = new HashMap<>();
  // Track instances to forward host lifecycle
  private static final java.util.Set<MapViewPlatformView> INSTANCES = java.util.Collections.newSetFromMap(new java.util.WeakHashMap<>());

  private ClusterManager<ClusterItemImpl> clusterManager;
  private boolean clusteringEnabled = false;
  private HeatmapTileProvider heatmapProvider;
  private TileOverlay heatmapOverlay;

  MapViewPlatformView(Context context, BinaryMessenger messenger, int viewId, Map<String, Object> params) {
    this.context = context;
    com.google.android.gms.maps.GoogleMapOptions opts = new com.google.android.gms.maps.GoogleMapOptions();
    try {
      Object lite = params.get("liteMode");
      if (lite instanceof Boolean && ((Boolean) lite)) opts.liteMode(true);
      Object mapId = params.get("mapId");
      if (mapId instanceof String && !((String) mapId).isEmpty()) {
        try { opts.mapId((String) mapId); } catch (Throwable ignored) {}
      }
    } catch (Throwable ignored) {}
    this.mapView = new MapView(context, opts);
    this.mapView.onCreate(null);
    try { this.mapView.setAlpha(0f); } catch (Throwable ignored) {}
    this.mapView.getMapAsync(this);
    this.channel = new MethodChannel(messenger, "google_maps_native_sdk/" + viewId);
    this.channel.setMethodCallHandler(this);

    final int maxMem = (int) (Runtime.getRuntime().maxMemory() / 1024);
    final int cacheSize = Math.min(1024 * 12, maxMem / 16); // up to ~12MB
    this.iconCache = new LruCache<String, Bitmap>(cacheSize) {
      @Override
      protected int sizeOf(@NonNull String key, @NonNull Bitmap value) {
        if (Build.VERSION.SDK_INT >= 19) return value.getAllocationByteCount() / 1024;
        return value.getByteCount() / 1024;
      }
    };

    // Apply initial params after mapReady
    this.pendingParams = params;
    // Disk cache dir
    this.diskCacheDir = new java.io.File(context.getCacheDir(), "gmns_icons");
    //noinspection ResultOfMethodCallIgnored
    this.diskCacheDir.mkdirs();
    synchronized (INSTANCES) { INSTANCES.add(this); }
  }

  private Map<String, Object> pendingParams;

  // Cluster item representation
  static class ClusterItemImpl implements ClusterItem {
    final LatLng position;
    final String id;
    final String title;
    final String snippet;
    final String iconUrl;
    final float anchorU;
    final float anchorV;
    final float rotation;
    final float zIndex;
    final boolean draggable;

    ClusterItemImpl(String id, LatLng position, String title, String snippet,
                    String iconUrl, float anchorU, float anchorV, float rotation, float zIndex, boolean draggable) {
      this.id = id;
      this.position = position;
      this.title = title;
      this.snippet = snippet;
      this.iconUrl = iconUrl;
      this.anchorU = anchorU;
      this.anchorV = anchorV;
      this.rotation = rotation;
      this.zIndex = zIndex;
      this.draggable = draggable;
    }

    @Override public LatLng getPosition() { return position; }
    @Override public String getTitle() { return title; }
    @Override public String getSnippet() { return snippet; }
    @Override public float getZIndex() { return zIndex; }
  }

  // Custom cluster renderer to apply custom marker icons for single items
  class ClusterRenderer extends com.google.maps.android.clustering.view.DefaultClusterRenderer<ClusterItemImpl> {
    ClusterRenderer(Context ctx, GoogleMap map, ClusterManager<ClusterItemImpl> mgr) {
      super(ctx, map, mgr);
    }

    @Override
    protected void onBeforeClusterItemRendered(@NonNull ClusterItemImpl item, @NonNull MarkerOptions markerOptions) {
      super.onBeforeClusterItemRendered(item, markerOptions);
      if (item.iconUrl != null && !item.iconUrl.isEmpty()) {
        Bitmap cached = iconCache.get(item.iconUrl);
        if (cached != null) {
          Bitmap scaled = scaleBitmapToDp(cached, 48);
          markerOptions.icon(BitmapDescriptorFactory.fromBitmap(scaled));
        } else {
          // async load and update after
          executor.submit(() -> {
            Bitmap bmp = null;
            try { bmp = loadBitmap(item.iconUrl); } catch (Throwable ignored) {}
            Bitmap scaled = bmp != null ? scaleBitmapToDp(bmp, 48) : null;
            if (scaled != null) iconCache.put(item.iconUrl, scaled);
            mapView.post(() -> {
              Marker m = markers.get(item.id);
              if (m != null && scaled != null) m.setIcon(BitmapDescriptorFactory.fromBitmap(scaled));
            });
          });
        }
      }
      markerOptions.anchor(item.anchorU, item.anchorV);
      markerOptions.rotation(item.rotation);
      markerOptions.zIndex(item.zIndex);
      markerOptions.draggable(item.draggable);
      if (item.title != null) markerOptions.title(item.title);
      if (item.snippet != null) markerOptions.snippet(item.snippet);
    }

    @Override
    protected void onClusterItemRendered(@NonNull ClusterItemImpl item, @NonNull Marker marker) {
      super.onClusterItemRendered(item, marker);
      markers.put(item.id, marker);
    }
  }

  @Override
  public View getView() { return mapView; }

  @Override
  public void dispose() {
    try {
      try { mapView.onPause(); } catch (Throwable ignored) {}
      try { mapView.onStop(); } catch (Throwable ignored) {}
      try { mapView.onDestroy(); } catch (Throwable ignored) {}
      executor.shutdownNow();
    } catch (Throwable ignored) {}
    synchronized (INSTANCES) { INSTANCES.remove(this); }
  }

  @Override
  public void onMapReady(@NonNull GoogleMap googleMap) {
    this.map = googleMap;
    map.setOnMarkerClickListener(this);
    try {
      map.setOnMapLoadedCallback(() -> {
        try { mapView.setAlpha(1f); } catch (Throwable ignored) {}
        try { channel.invokeMethod("event#onMapLoaded", null); } catch (Throwable ignored) {}
      });
    } catch (Throwable ignored) {}
    if (pendingParams != null) applyInitialParams(pendingParams);

    // Setup clustering if requested
    try {
      Object ce = pendingParams != null ? pendingParams.get("clusterEnabled") : null;
      if (ce instanceof Boolean && ((Boolean) ce)) {
        enableClustering(true);
      }
    } catch (Throwable ignored) {}
  }

  private void enableClustering(boolean enabled) {
    clusteringEnabled = enabled;
    if (enabled) {
      if (clusterManager == null) {
        clusterManager = new ClusterManager<>(context, map);
        ClusterRenderer renderer = new ClusterRenderer(context, map, clusterManager);
        clusterManager.setRenderer(renderer);
        map.setOnCameraIdleListener(clusterManager);
        map.setOnMarkerClickListener(clusterManager);
        clusterManager.setOnClusterItemClickListener(item -> {
          try { channel.invokeMethod("event#onMarkerTap", item.id); } catch (Throwable ignored) {}
          return false;
        });
      }
      // Migrate existing normal markers into cluster items
      if (!markers.isEmpty()) {
        for (Map.Entry<String, Marker> e : new ArrayList<>(markers.entrySet())) {
          Marker mk = e.getValue();
          String id = e.getKey();
          LatLng p = mk.getPosition();
          ClusterItemImpl item = new ClusterItemImpl(id, p, mk.getTitle(), mk.getSnippet(), "", 0.5f, 0.62f, 0f, 0f, false);
          clusterItems.put(id, item);
          clusterManager.addItem(item);
          mk.remove();
        }
        markers.clear();
        clusterManager.cluster();
      }
    } else {
      if (clusterManager != null) {
        clusterManager.clearItems();
        clusterItems.clear();
        // keep clusterManager instance but detach listeners so clicks go back to this
        map.setOnMarkerClickListener(this);
        map.setOnCameraIdleListener(null);
      }
    }
  }

  private void applyInitialParams(Map<String, Object> params) {
    try {
      @SuppressWarnings("unchecked")
      Map<String, Object> cam = (Map<String, Object>) params.get("initialCameraPosition");
      if (cam != null) {
        @SuppressWarnings("unchecked") Map<String, Object> t = (Map<String, Object>) cam.get("target");
        double lat = toDouble(t.get("lat"));
        double lng = toDouble(t.get("lng"));
        Double zoomD = toNullableDouble(cam.get("zoom"));
        Double tiltD = toNullableDouble(cam.get("tilt"));
        Double bearingD = toNullableDouble(cam.get("bearing"));
        CameraPosition current = map.getCameraPosition();
        float zoom = zoomD != null ? zoomD.floatValue() : current.zoom;
        float tilt = tiltD != null ? tiltD.floatValue() : current.tilt;
        float bearing = bearingD != null ? bearingD.floatValue() : current.bearing;
        map.moveCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition(new LatLng(lat, lng), zoom, tilt, bearing)));
      }
      Boolean traffic = (Boolean) params.get("trafficEnabled");
      if (traffic != null) map.setTrafficEnabled(traffic);
      Boolean buildings = (Boolean) params.get("buildingsEnabled");
      if (buildings != null) map.setBuildingsEnabled(buildings);
      Boolean myLoc = (Boolean) params.get("myLocationEnabled");
      if (myLoc != null) {
        try { map.setMyLocationEnabled(myLoc); } catch (SecurityException se) { Log.w("GMNS", "Location permission missing"); }
      }
      Boolean indoor = (Boolean) params.get("indoorEnabled");
      if (indoor != null) map.setIndoorEnabled(indoor);
      Boolean indoorPicker = (Boolean) params.get("indoorLevelPicker");
      if (indoorPicker != null) {
        try { map.getUiSettings().setIndoorLevelPickerEnabled(indoorPicker); } catch (Throwable ignored) {}
      }
      @SuppressWarnings("unchecked") Map<String, Object> pad = (Map<String, Object>) params.get("padding");
      if (pad != null) {
        map.setPadding((int) toDouble(pad.get("left")), (int) toDouble(pad.get("top")), (int) toDouble(pad.get("right")), (int) toDouble(pad.get("bottom")));
      }
      String style = (String) params.get("mapStyle");
      if (style != null && !style.isEmpty()) {
        try {
          map.setMapStyle(new com.google.android.gms.maps.model.MapStyleOptions(style));
        } catch (Throwable t2) { Log.e("GMNS", "Invalid map style", t2); }
      }
    } catch (Throwable t) {
      Log.e("GMNS", "applyInitialParams error", t);
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (map == null) { result.error("map_not_ready", "Map not ready", null); return; }
    switch (call.method) {
      case "map#animateCamera": {
        @SuppressWarnings("unchecked") Map<String, Object> args = (Map<String, Object>) call.arguments;
        @SuppressWarnings("unchecked") Map<String, Object> target = (Map<String, Object>) args.get("target");
        double lat = toDouble(target.get("lat"));
        double lng = toDouble(target.get("lng"));
        CameraPosition current = map.getCameraPosition();
        Double zoom = toNullableDouble(args.get("zoom"));
        Double tilt = toNullableDouble(args.get("tilt"));
        Double bearing = toNullableDouble(args.get("bearing"));
        Integer durationMs = args.get("durationMs") instanceof Number ? ((Number) args.get("durationMs")).intValue() : null;

        CameraPosition pos = new CameraPosition(
            new LatLng(lat, lng),
            zoom != null ? zoom.floatValue() : current.zoom,
            tilt != null ? tilt.floatValue() : current.tilt,
            bearing != null ? bearing.floatValue() : current.bearing
        );
        com.google.android.gms.maps.CameraUpdate update = CameraUpdateFactory.newCameraPosition(pos);
        if (durationMs != null) map.animateCamera(update, durationMs, null);
        else map.animateCamera(update);
        result.success(null);
        break;
      }
      case "map#moveCamera": {
        @SuppressWarnings("unchecked") Map<String, Object> target = (Map<String, Object>) ((Map<String, Object>) call.arguments).get("target");
        double lat = toDouble(target.get("lat"));
        double lng = toDouble(target.get("lng"));
        Double zoomD = toNullableDouble(((Map) call.arguments).get("zoom"));
        Double tiltD = toNullableDouble(((Map) call.arguments).get("tilt"));
        Double bearingD = toNullableDouble(((Map) call.arguments).get("bearing"));
        CameraPosition current = map.getCameraPosition();
        float zoom = zoomD != null ? zoomD.floatValue() : current.zoom;
        float tilt = tiltD != null ? tiltD.floatValue() : current.tilt;
        float bearing = bearingD != null ? bearingD.floatValue() : current.bearing;
        com.google.android.gms.maps.CameraUpdate update = CameraUpdateFactory.newCameraPosition(new CameraPosition(new LatLng(lat, lng), zoom, tilt, bearing));
        map.moveCamera(update);
        result.success(null);
        break;
      }
      case "map#animateToBounds": {
        @SuppressWarnings("unchecked") Map<String, Object> ne = (Map<String, Object>) ((Map) call.arguments).get("ne");
        @SuppressWarnings("unchecked") Map<String, Object> sw = (Map<String, Object>) ((Map) call.arguments).get("sw");
        double padding = toDouble(((Map) call.arguments).get("padding"));
        LatLngBounds bounds = new LatLngBounds(new LatLng(toDouble(sw.get("lat")), toDouble(sw.get("lng"))), new LatLng(toDouble(ne.get("lat")), toDouble(ne.get("lng"))));
        map.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds, (int) padding));
        result.success(null);
        break;
      }
      case "map#setTrafficEnabled": {
        boolean enabled = (Boolean) call.arguments;
        map.setTrafficEnabled(enabled);
        result.success(null);
        break;
      }
      case "map#setMyLocationEnabled": {
        boolean enabled = (Boolean) call.arguments;
        try { map.setMyLocationEnabled(enabled); result.success(null);} catch (SecurityException se){ result.error("no_permission","Location permission missing", null);} 
        break;
      }
      case "map#setPadding": {
        @SuppressWarnings("unchecked") Map<String, Object> pad = (Map<String, Object>) call.arguments;
        map.setPadding((int) toDouble(pad.get("left")), (int) toDouble(pad.get("top")), (int) toDouble(pad.get("right")), (int) toDouble(pad.get("bottom")));
        result.success(null);
        break;
      }
      case "map#setStyle": {
        String style = (String) call.arguments;
        try {
          boolean ok = map.setMapStyle(style == null ? null : new com.google.android.gms.maps.model.MapStyleOptions(style));
          result.success(ok);
        } catch (Throwable t) { result.error("style_error","Invalid style", t.toString()); }
        break;
      }
      case "markers#add": {
        @SuppressWarnings("unchecked") Map<String, Object> m = (Map<String, Object>) call.arguments;
        addMarkerInternal(m);
        result.success(null);
        break;
      }
      case "markers#update": {
        @SuppressWarnings("unchecked") Map<String, Object> m = (Map<String, Object>) call.arguments;
        String id = (String) m.get("id");
        if (clusteringEnabled && clusterManager != null) {
          ClusterItemImpl old = clusterItems.remove(id);
          if (old != null) try { clusterManager.removeItem(old); } catch (Throwable ignored) {}
          @SuppressWarnings("unchecked") Map<String, Object> pos = (Map<String, Object>) m.get("position");
          double lat = pos != null ? toDouble(pos.get("lat")) : old != null ? old.position.latitude : 0;
          double lng = pos != null ? toDouble(pos.get("lng")) : old != null ? old.position.longitude : 0;
          double rotation = m.get("rotation") != null ? toDouble(m.get("rotation")) : (old != null ? old.rotation : 0);
          ClusterItemImpl item = new ClusterItemImpl(
              id,
              new LatLng(lat, lng),
              old != null ? old.title : null,
              old != null ? old.snippet : null,
              old != null ? old.iconUrl : "",
              old != null ? old.anchorU : 0.5f,
              old != null ? old.anchorV : 0.62f,
              (float) rotation,
              old != null ? old.zIndex : 0f,
              old != null && old.draggable
          );
          clusterItems.put(id, item);
          clusterManager.addItem(item);
          clusterManager.cluster();
        } else {
          Marker marker = markers.get(id);
          if (marker != null) {
            @SuppressWarnings("unchecked") Map<String, Object> pos = (Map<String, Object>) m.get("position");
            if (pos != null) marker.setPosition(new LatLng(toDouble(pos.get("lat")), toDouble(pos.get("lng"))));
            if (m.get("rotation") != null) marker.setRotation(((Double) toDouble(m.get("rotation"))).floatValue());
          }
        }
        result.success(null);
        break;
      }
      case "markers#remove": {
        String id = (String) call.arguments;
        if (clusteringEnabled && clusterManager != null) {
          ClusterItemImpl old = clusterItems.remove(id);
          if (old != null) try { clusterManager.removeItem(old); } catch (Throwable ignored) {}
          clusterManager.cluster();
        } else {
          Marker marker = markers.remove(id);
          if (marker != null) marker.remove();
        }
        result.success(null);
        break;
      }
      case "markers#clear": {
        if (clusteringEnabled && clusterManager != null) {
          clusterManager.clearItems();
          clusterItems.clear();
          clusterManager.cluster();
        }
        for (Marker mk : markers.values()) mk.remove();
        markers.clear();
        result.success(null);
        break;
      }
      case "polylines#add": {
        @SuppressWarnings("unchecked") Map<String, Object> p = (Map<String, Object>) call.arguments;
        String id = (String) p.get("id");
        @SuppressWarnings("unchecked") List<Map<String, Object>> pts = (List<Map<String, Object>>) p.get("points");
        PolylineOptions opts = new PolylineOptions();
        for (Map<String, Object> pt : pts) {
          opts.add(new LatLng(toDouble(pt.get("lat")), toDouble(pt.get("lng"))));
        }
        int color = ((Number) p.get("color")).intValue();
        double width = toDouble(p.get("width"));
        boolean geodesic = (Boolean) p.get("geodesic");
        boolean dotted = (Boolean) p.get("dotted");
        opts.color(color).width((float) width).geodesic(geodesic).pattern(dotted ? java.util.Arrays.asList(new com.google.android.gms.maps.model.Dot(), new com.google.android.gms.maps.model.Gap(12)) : null);
        com.google.android.gms.maps.model.Polyline polyline = map.addPolyline(opts);
        com.google.android.gms.maps.model.Polyline old = polylines.put(id, polyline);
        if (old != null) old.remove();
        result.success(null);
        break;
      }
      case "polylines#updatePoints": {
        @SuppressWarnings("unchecked") Map<String, Object> p = (Map<String, Object>) call.arguments;
        String id = (String) p.get("id");
        @SuppressWarnings("unchecked") List<Map<String, Object>> pts = (List<Map<String, Object>>) p.get("points");
        com.google.android.gms.maps.model.Polyline poly = polylines.get(id);
        if (poly != null) {
          java.util.List<LatLng> list = new java.util.ArrayList<>(pts.size());
          for (Map<String, Object> pt : pts) list.add(new LatLng(toDouble(pt.get("lat")), toDouble(pt.get("lng"))));
          poly.setPoints(list);
        }
        result.success(null);
        break;
      }
      case "polylines#remove": {
        String id = (String) call.arguments;
        com.google.android.gms.maps.model.Polyline p = polylines.remove(id);
        if (p != null) p.remove();
        result.success(null);
        break;
      }
      case "polylines#clear": {
        for (com.google.android.gms.maps.model.Polyline p : polylines.values()) p.remove();
        polylines.clear();
        result.success(null);
        break;
      }
      case "map#takeSnapshot": {
        map.snapshot(bmp -> {
          if (bmp == null) { channel.invokeMethod("snapshot#error", null); return; }
          java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
          bmp.compress(Bitmap.CompressFormat.PNG, 100, bos);
          result.success(bos.toByteArray());
        });
        break;
      }
      case "map#setClusteringEnabled": {
        boolean enabled = (Boolean) call.arguments;
        enableClustering(enabled);
        result.success(null);
        break;
      }
      case "heatmap#set": {
        @SuppressWarnings("unchecked") Map<String, Object> args = (Map<String, Object>) call.arguments;
        @SuppressWarnings("unchecked") List<Map<String, Object>> pts = (List<Map<String, Object>>) args.get("points");
        java.util.List<com.google.android.gms.maps.model.LatLng> data = new java.util.ArrayList<>(pts.size());
        for (Map<String, Object> pt : pts) data.add(new LatLng(toDouble(pt.get("lat")), toDouble(pt.get("lng"))));
        int radius = args.get("radius") instanceof Number ? ((Number) args.get("radius")).intValue() : 20;
        double opacity = args.get("opacity") instanceof Number ? ((Number) args.get("opacity")).doubleValue() : 0.7;
        if (heatmapOverlay != null) { heatmapOverlay.remove(); heatmapOverlay = null; }
        heatmapProvider = new HeatmapTileProvider.Builder().data(data).radius(radius).opacity(opacity).build();
        heatmapOverlay = map.addTileOverlay(new TileOverlayOptions().tileProvider(heatmapProvider));
        result.success(null);
        break;
      }
      case "heatmap#clear": {
        if (heatmapOverlay != null) { heatmapOverlay.remove(); heatmapOverlay = null; }
        heatmapProvider = null;
        result.success(null);
        break;
      }
      case "tiles#add": {
        @SuppressWarnings("unchecked") Map<String, Object> args = (Map<String, Object>) call.arguments;
        String id = (String) args.get("id");
        String template = (String) args.get("template");
        int tileSize = args.get("tileSize") instanceof Number ? ((Number) args.get("tileSize")).intValue() : 256;
        double opacity = args.get("opacity") instanceof Number ? ((Number) args.get("opacity")).doubleValue() : 1.0;
        double zIndex = args.get("zIndex") instanceof Number ? ((Number) args.get("zIndex")).doubleValue() : 0.0;
        UrlTileProvider provider = new UrlTileProvider(tileSize, tileSize) {
          @Override
          public java.net.URL getTileUrl(int x, int y, int zoom) {
            try {
              String url = template.replace("{x}", String.valueOf(x)).replace("{y}", String.valueOf(y)).replace("{z}", String.valueOf(zoom));
              return new java.net.URL(url);
            } catch (Exception e) { return null; }
          }
        };
        TileOverlay old = tileOverlays.remove(id);
        if (old != null) old.remove();
        TileOverlay overlay = map.addTileOverlay(new TileOverlayOptions().tileProvider(provider).zIndex((float) zIndex).transparency((float) (1.0 - Math.max(0.0, Math.min(1.0, opacity)))));
        tileOverlays.put(id, overlay);
        result.success(null);
        break;
      }
      case "tiles#remove": {
        String id = (String) call.arguments;
        TileOverlay o = tileOverlays.remove(id);
        if (o != null) o.remove();
        result.success(null);
        break;
      }
      case "tiles#clear": {
        for (TileOverlay o : tileOverlays.values()) { o.remove(); }
        tileOverlays.clear();
        result.success(null);
        break;
      }
      case "map#setIndoorEnabled": {
        boolean enabled = (Boolean) call.arguments;
        map.setIndoorEnabled(enabled);
        result.success(null);
        break;
      }
      case "map#setIndoorLevelPickerEnabled": {
        boolean enabled = (Boolean) call.arguments;
        try { map.getUiSettings().setIndoorLevelPickerEnabled(enabled); } catch (Throwable ignored) {}
        result.success(null);
        break;
      }
      case "map#setMapId": {
        // Not supported at runtime on Android via Maps SDK; requires options at creation.
        result.error("not_supported", "Android: mapId can only be set at creation (GoogleMapOptions.mapId)", null);
        break;
      }
      case "map#dispose": {
        dispose();
        result.success(null);
        break;
      }
      default:
        result.notImplemented();
    }
  }

  private void addMarkerInternal(Map<String, Object> m) {
    String id = (String) m.get("id");
    @SuppressWarnings("unchecked") Map<String, Object> pos = (Map<String, Object>) m.get("position");
    double lat = toDouble(pos.get("lat"));
    double lng = toDouble(pos.get("lng"));
    String title = (String) m.get("title");
    String snippet = (String) m.get("snippet");
    String iconUrl = (String) m.get("iconUrl");
    double anchorU = toDouble(m.get("anchorU"));
    double anchorV = toDouble(m.get("anchorV"));
    double rotation = toDouble(m.get("rotation"));
    boolean draggable = (Boolean) m.get("draggable");
    double zIndex = toDouble(m.get("zIndex"));

    if (clusteringEnabled && clusterManager != null) {
      ClusterItemImpl old = clusterItems.remove(id);
      if (old != null) try { clusterManager.removeItem(old); } catch (Throwable ignored) {}
      ClusterItemImpl item = new ClusterItemImpl(
          id,
          new LatLng(lat, lng),
          title,
          snippet,
          iconUrl != null ? iconUrl : "",
          (float) anchorU,
          (float) anchorV,
          (float) rotation,
          (float) zIndex,
          draggable
      );
      clusterItems.put(id, item);
      clusterManager.addItem(item);
      clusterManager.cluster();
      return;
    }

    Marker existing = markers.remove(id);
    if (existing != null) existing.remove();

    MarkerOptions opts = new MarkerOptions()
        .position(new LatLng(lat, lng))
        .anchor((float) anchorU, (float) anchorV)
        .rotation((float) rotation)
        .zIndex((float) zIndex)
        .draggable(draggable);
    if (title != null) opts.title(title);
    if (snippet != null) opts.snippet(snippet);

    if (iconUrl != null && !iconUrl.isEmpty()) {
      Bitmap cached = iconCache.get(iconUrl);
      if (cached != null) {
        Bitmap scaled = scaleBitmapToDp(cached, 48);
        opts.icon(BitmapDescriptorFactory.fromBitmap(scaled));
        Marker mk = map.addMarker(opts);
        if (mk != null) markers.put(id, mk);
      } else {
        // load async
        executor.submit(() -> {
          Bitmap bmp = null;
          try { bmp = loadBitmap(iconUrl); } catch (Throwable ignored) {}
          final Bitmap ready = bmp;
          mapView.post(() -> {
            Bitmap scaled = ready != null ? scaleBitmapToDp(ready, 48) : null;
            if (scaled != null) iconCache.put(iconUrl, scaled);
            MarkerOptions myOpts = new MarkerOptions()
                .position(new LatLng(lat, lng))
                .anchor((float) anchorU, (float) anchorV)
                .rotation((float) rotation)
                .zIndex((float) zIndex)
                .draggable(draggable)
                .title(title)
                .snippet(snippet);
            if (scaled != null) myOpts.icon(BitmapDescriptorFactory.fromBitmap(scaled));
            Marker mk = map.addMarker(myOpts);
            if (mk != null) markers.put(id, mk);
          });
        });
      }
    } else {
      Marker mk = map.addMarker(opts);
      if (mk != null) markers.put(id, mk);
    }
  }

  private Bitmap loadBitmap(String urlStr) throws Exception {
    final String name = md5(urlStr) + ".png";
    final java.io.File f = new java.io.File(diskCacheDir, name);
    if (f.exists()) {
      Bitmap b = BitmapFactory.decodeFile(f.getAbsolutePath());
      if (b != null) return b;
    }
    URL url = new URL(urlStr);
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setConnectTimeout(4000);
    conn.setReadTimeout(4000);
    conn.connect();
    try (InputStream is = conn.getInputStream()) {
      Bitmap bmp = BitmapFactory.decodeStream(is);
      if (bmp != null) {
        // save PNG
        try (java.io.FileOutputStream fos = new java.io.FileOutputStream(f)) {
          bmp.compress(Bitmap.CompressFormat.PNG, 100, fos);
        } catch (Throwable ignored) {}
      }
      return bmp;
    } finally {
      conn.disconnect();
    }
  }

  private static String md5(String s) {
    try {
      java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
      byte[] bytes = md.digest(s.getBytes(java.nio.charset.StandardCharsets.UTF_8));
      StringBuilder sb = new StringBuilder();
      for (byte b : bytes) sb.append(String.format("%02x", b));
      return sb.toString();
    } catch (Exception e) {
      return Integer.toHexString(s.hashCode());
    }
  }

  private static double toDouble(Object o) { return o == null ? 0 : ((Number) o).doubleValue(); }
  private static Double toNullableDouble(Object o) { return o == null ? null : ((Number) o).doubleValue(); }

  private Bitmap scaleBitmapToDp(Bitmap bmp, int maxDp) {
    try {
      float density = context.getResources().getDisplayMetrics().density;
      int maxPx = Math.max(1, (int) (maxDp * density));
      int w = bmp.getWidth();
      int h = bmp.getHeight();
      int maxSide = Math.max(w, h);
      if (maxSide <= maxPx) return bmp;
      float scale = (float) maxPx / (float) maxSide;
      int nw = Math.max(1, Math.round(w * scale));
      int nh = Math.max(1, Math.round(h * scale));
      return Bitmap.createScaledBitmap(bmp, nw, nh, true);
    } catch (Throwable t) { return bmp; }
  }

  // Lifecycle hooks forwarded by plugin
  void onHostStart() { try { mapView.onStart(); } catch (Throwable ignored) {} }
  void onHostResume() { try { mapView.onResume(); } catch (Throwable ignored) {} }
  void onHostPause() { try { mapView.onPause(); } catch (Throwable ignored) {} }
  void onHostStop() { try { mapView.onStop(); } catch (Throwable ignored) {} }
  void onHostDestroy() { try { mapView.onDestroy(); } catch (Throwable ignored) {} }

  static void dispatchStart() { synchronized (INSTANCES) { for (MapViewPlatformView v : INSTANCES) v.onHostStart(); } }
  static void dispatchResume() { synchronized (INSTANCES) { for (MapViewPlatformView v : INSTANCES) v.onHostResume(); } }
  static void dispatchPause() { synchronized (INSTANCES) { for (MapViewPlatformView v : INSTANCES) v.onHostPause(); } }
  static void dispatchStop() { synchronized (INSTANCES) { for (MapViewPlatformView v : INSTANCES) v.onHostStop(); } }
  static void dispatchDestroy() { synchronized (INSTANCES) { for (MapViewPlatformView v : INSTANCES) v.onHostDestroy(); } }

  @Override
  public boolean onMarkerClick(@NonNull Marker marker) {
    for (Map.Entry<String, Marker> e : markers.entrySet()) {
      if (e.getValue().equals(marker)) {
        channel.invokeMethod("event#onMarkerTap", e.getKey());
        break;
      }
    }
    return false; // allow default behavior
  }
}
