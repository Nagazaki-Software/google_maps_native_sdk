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

  MapViewPlatformView(Context context, BinaryMessenger messenger, int viewId, Map<String, Object> params) {
    this.context = context;
    this.mapView = new MapView(context);
    this.mapView.onCreate(null);
    this.mapView.onResume();
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
  }

  private Map<String, Object> pendingParams;

  @Override
  public View getView() { return mapView; }

  @Override
  public void dispose() {
    try {
      mapView.onPause();
      mapView.onDestroy();
      executor.shutdownNow();
    } catch (Throwable ignored) {}
  }

  @Override
  public void onMapReady(@NonNull GoogleMap googleMap) {
    this.map = googleMap;
    map.setOnMarkerClickListener(this);
    if (pendingParams != null) applyInitialParams(pendingParams);
  }

  private void applyInitialParams(Map<String, Object> params) {
    try {
      @SuppressWarnings("unchecked")
      Map<String, Object> cam = (Map<String, Object>) params.get("initialCameraPosition");
      if (cam != null) {
        @SuppressWarnings("unchecked") Map<String, Object> t = (Map<String, Object>) cam.get("target");
        double lat = toDouble(t.get("lat"));
        double lng = toDouble(t.get("lng"));
        double zoom = toDouble(cam.get("zoom"));
        map.moveCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition(new LatLng(lat, lng), (float) zoom, 0, 0)));
      }
      Boolean traffic = (Boolean) params.get("trafficEnabled");
      if (traffic != null) map.setTrafficEnabled(traffic);
      Boolean buildings = (Boolean) params.get("buildingsEnabled");
      if (buildings != null) map.setBuildingsEnabled(buildings);
      Boolean myLoc = (Boolean) params.get("myLocationEnabled");
      if (myLoc != null) {
        try { map.setMyLocationEnabled(myLoc); } catch (SecurityException se) { Log.w("GMNS", "Location permission missing"); }
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
      case "map#moveCamera": {
        @SuppressWarnings("unchecked") Map<String, Object> target = (Map<String, Object>) ((Map<String, Object>) call.arguments).get("target");
        double lat = toDouble(target.get("lat"));
        double lng = toDouble(target.get("lng"));
        Double zoom = toNullableDouble(((Map) call.arguments).get("zoom"));
        if (zoom != null) {
          map.moveCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(lat, lng), zoom.floatValue()));
        } else {
          map.moveCamera(CameraUpdateFactory.newLatLng(new LatLng(lat, lng)));
        }
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
        Marker marker = markers.get(id);
        if (marker != null) {
          @SuppressWarnings("unchecked") Map<String, Object> pos = (Map<String, Object>) m.get("position");
          if (pos != null) marker.setPosition(new LatLng(toDouble(pos.get("lat")), toDouble(pos.get("lng"))));
          if (m.get("rotation") != null) marker.setRotation(((Double) toDouble(m.get("rotation"))).floatValue());
        }
        result.success(null);
        break;
      }
      case "markers#remove": {
        String id = (String) call.arguments;
        Marker marker = markers.remove(id);
        if (marker != null) marker.remove();
        result.success(null);
        break;
      }
      case "markers#clear": {
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
        opts.icon(BitmapDescriptorFactory.fromBitmap(cached));
        Marker mk = map.addMarker(opts);
        if (mk != null) markers.put(id, mk);
      } else {
        // load async
        executor.submit(() -> {
          Bitmap bmp = null;
          try { bmp = loadBitmap(iconUrl); } catch (Throwable ignored) {}
          final Bitmap ready = bmp;
          mapView.post(() -> {
            if (ready != null) iconCache.put(iconUrl, ready);
            MarkerOptions myOpts = new MarkerOptions()
                .position(new LatLng(lat, lng))
                .anchor((float) anchorU, (float) anchorV)
                .rotation((float) rotation)
                .zIndex((float) zIndex)
                .draggable(draggable)
                .title(title)
                .snippet(snippet);
            if (ready != null) myOpts.icon(BitmapDescriptorFactory.fromBitmap(ready));
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
