package com.example.google_maps_native_sdk;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformViewRegistry;

/** GoogleMapsNativeSdkPlugin */
public class GoogleMapsNativeSdkPlugin implements FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {

  private Application application;
  private Activity activity;
  private EventChannel headingChannel;
  private MethodChannel audioChannel;
  private MethodChannel navUiChannel;
  private android.hardware.SensorManager sensorManager;
  private android.hardware.Sensor rotationSensor;
  private android.hardware.SensorEventListener headingListener;
  private android.media.AudioManager audioManager;
  private Object audioFocusRequest; // AudioFocusRequest (API>=26) or null

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    BinaryMessenger messenger = binding.getBinaryMessenger();
    PlatformViewRegistry registry = binding.getPlatformViewRegistry();
    registry.registerViewFactory("google_maps_native_sdk/map_view",
        new MapViewFactory(messenger));

    // Heading EventChannel
    headingChannel = new EventChannel(messenger, "google_maps_native_sdk/heading");
    headingChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override public void onListen(Object args, final EventChannel.EventSink events) {
        try {
          sensorManager = (android.hardware.SensorManager) binding.getApplicationContext().getSystemService(android.content.Context.SENSOR_SERVICE);
          if (sensorManager != null) {
            rotationSensor = sensorManager.getDefaultSensor(android.hardware.Sensor.TYPE_ROTATION_VECTOR);
            if (rotationSensor != null) {
              headingListener = new android.hardware.SensorEventListener() {
                final float[] rot = new float[9];
                final float[] ori = new float[3];
                @Override public void onSensorChanged(android.hardware.SensorEvent event) {
                  try {
                    android.hardware.SensorManager.getRotationMatrixFromVector(rot, event.values);
                    android.hardware.SensorManager.getOrientation(rot, ori);
                    float azimuthRad = ori[0];
                    double deg = Math.toDegrees(azimuthRad);
                    if (deg < 0) deg += 360.0;
                    events.success((float) deg);
                  } catch (Throwable t) { /* ignore */ }
                }
                @Override public void onAccuracyChanged(android.hardware.Sensor sensor, int accuracy) { }
              };
              sensorManager.registerListener(headingListener, rotationSensor, android.hardware.SensorManager.SENSOR_DELAY_GAME);
            } else {
              events.error("no_sensor", "Rotation vector not available", null);
            }
          } else {
            events.error("no_sm", "SensorManager not available", null);
          }
        } catch (Throwable t) {
          events.error("err", t.getMessage(), null);
        }
      }
      @Override public void onCancel(Object args) {
        try {
          if (sensorManager != null && headingListener != null) {
            sensorManager.unregisterListener(headingListener);
          }
          headingListener = null;
          rotationSensor = null;
          sensorManager = null;
        } catch (Throwable ignored) {}
      }
    });

    // Audio focus MethodChannel (Android only)
    audioChannel = new MethodChannel(messenger, "google_maps_native_sdk/audio");
    audioChannel.setMethodCallHandler((call, result) -> {
      String m = call.method;
      if ("audio#request".equals(m)) {
        try {
          if (audioManager == null) {
            audioManager = (android.media.AudioManager) binding.getApplicationContext().getSystemService(android.content.Context.AUDIO_SERVICE);
          }
          if (audioManager == null) { result.success(false); return; }
          if (android.os.Build.VERSION.SDK_INT >= 26) {
            android.media.AudioAttributes attrs = new android.media.AudioAttributes.Builder()
                .setUsage(android.media.AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                .build();
            android.media.AudioFocusRequest req = new android.media.AudioFocusRequest.Builder(android.media.AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener(focusChange -> {})
                .build();
            int r = audioManager.requestAudioFocus(req);
            audioFocusRequest = req;
            result.success(r == android.media.AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
          } else {
            int r = audioManager.requestAudioFocus(focusChange -> {}, android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK);
            result.success(r == android.media.AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
          }
        } catch (Throwable t) {
          result.success(false);
        }
      } else if ("audio#abandon".equals(m)) {
        try {
          if (audioManager != null) {
            if (android.os.Build.VERSION.SDK_INT >= 26 && audioFocusRequest instanceof android.media.AudioFocusRequest) {
              audioManager.abandonAudioFocusRequest((android.media.AudioFocusRequest) audioFocusRequest);
            } else {
              audioManager.abandonAudioFocus(focusChange -> {});
            }
          }
        } catch (Throwable ignored) {}
        result.success(null);
      } else {
        result.notImplemented();
      }
    });

    // Navigation UI bridge (Android)
    navUiChannel = new MethodChannel(messenger, "google_maps_native_sdk/nav_ui");
    navUiChannel.setMethodCallHandler((call, result) -> {
      String m = call.method;
      if ("nav_ui#isAvailable".equals(m)) {
        boolean available = isNavigationSdkAvailable();
        result.success(available);
      } else if ("nav_ui#start".equals(m)) {
        if (activity == null) { result.success(false); return; }
        android.content.Intent intent = new android.content.Intent(activity, NavUiActivity.class);
        if (call.arguments instanceof java.util.Map) {
          @SuppressWarnings("unchecked") java.util.Map<String, Object> args = (java.util.Map<String, Object>) call.arguments;
          try {
            org.json.JSONObject json = new org.json.JSONObject(args);
            intent.putExtra("nav_args_json", json.toString());
          } catch (Throwable ignored) {}
        }
        try {
          activity.startActivity(intent);
          result.success(true);
        } catch (Throwable t) {
          result.success(false);
        }
      } else if ("nav_ui#stop".equals(m)) {
        try { NavUiActivity.finishCurrent(); } catch (Throwable ignored) {}
        result.success(null);
      } else {
        result.notImplemented();
      }
    });
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    try {
      if (headingChannel != null) headingChannel.setStreamHandler(null);
    } catch (Throwable ignored) {}
    headingChannel = null;
    audioChannel = null;
    navUiChannel = null;
  }

  // Reflection-based check so the plugin compiles without Navigation SDK dependency
  public static boolean isNavigationSdkAvailable() {
    try { Class.forName("com.google.android.libraries.navigation.NavigationApi"); return true; } catch (Throwable ignored) {}
    try { Class.forName("com.google.android.libraries.navigationui.NavigationActivity"); return true; } catch (Throwable ignored) {}
    try { Class.forName("com.google.android.libraries.navigation.ui.NavigationFragment"); return true; } catch (Throwable ignored) {}
    return false;
  }

  // ActivityAware
  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    this.application = this.activity.getApplication();
    this.application.registerActivityLifecycleCallbacks(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    detachActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    detachActivity();
  }

  private void detachActivity() {
    if (this.application != null) {
      try { this.application.unregisterActivityLifecycleCallbacks(this); } catch (Throwable ignored) {}
    }
    this.application = null;
    this.activity = null;
  }

  // ActivityLifecycleCallbacks: forward to MapView instances
  @Override public void onActivityCreated(@NonNull Activity a, Bundle b) { }
  @Override public void onActivityStarted(@NonNull Activity a) { if (a == activity) MapViewPlatformView.dispatchStart(); }
  @Override public void onActivityResumed(@NonNull Activity a) { if (a == activity) MapViewPlatformView.dispatchResume(); }
  @Override public void onActivityPaused(@NonNull Activity a) { if (a == activity) MapViewPlatformView.dispatchPause(); }
  @Override public void onActivityStopped(@NonNull Activity a) { if (a == activity) MapViewPlatformView.dispatchStop(); }
  @Override public void onActivitySaveInstanceState(@NonNull Activity a, @NonNull Bundle outState) { }
  @Override public void onActivityDestroyed(@NonNull Activity a) { if (a == activity) MapViewPlatformView.dispatchDestroy(); }
}

// Lightweight host activity to embed Google Navigation SDK UI if available.
class NavUiActivity extends android.app.Activity {
  private static java.lang.ref.WeakReference<NavUiActivity> CURRENT;

  static void finishCurrent() {
    NavUiActivity a = CURRENT != null ? CURRENT.get() : null;
    if (a != null) a.finish();
  }

  @Override protected void onCreate(android.os.Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    CURRENT = new java.lang.ref.WeakReference<>(this);
    // Try to inflate Navigation SDK view reflectively (if present), else show placeholder
    android.widget.FrameLayout root = new android.widget.FrameLayout(this);
    root.setLayoutParams(new android.widget.FrameLayout.LayoutParams(
        android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
        android.widget.FrameLayout.LayoutParams.MATCH_PARENT));
    setContentView(root);

    boolean available = GoogleMapsNativeSdkPlugin.isNavigationSdkAvailable();
    if (available) {
      // Parse args JSON
      double oLat=0,oLng=0,dLat=0,dLng=0; String apiKey=""; String mapId=null; String language=""; String themeMode="auto";
      int colorPrimary=0, colorOnPrimary=0, colorSurface=0, colorOnSurface=0;
      String jsonStr = getIntent().getStringExtra("nav_args_json");
      if (jsonStr != null) {
        try {
          org.json.JSONObject j = new org.json.JSONObject(jsonStr);
          apiKey = j.optString("apiKey", "");
          language = j.optString("languageCode", "");
          themeMode = j.optString("themeMode", "auto");
          if (j.has("mapId")) mapId = j.optString("mapId", null);
          colorPrimary = (int) j.optLong("colorPrimary", 0);
          colorOnPrimary = (int) j.optLong("colorOnPrimary", 0);
          colorSurface = (int) j.optLong("colorSurface", 0);
          colorOnSurface = (int) j.optLong("colorOnSurface", 0);
          org.json.JSONObject o = j.optJSONObject("origin");
          if (o != null) { oLat = o.optDouble("lat", 0); oLng = o.optDouble("lng", 0); }
          org.json.JSONObject d = j.optJSONObject("destination");
          if (d != null) { dLat = d.optDouble("lat", 0); dLng = d.optDouble("lng", 0); }
        } catch (Throwable ignored) {}
      }
      // Try Navigation UI Activity first
      try {
        Class<?> act = Class.forName("com.google.android.libraries.navigation.ui.NavigationActivity");
        android.content.Intent i = new android.content.Intent(this, act);
        i.putExtra("origin_lat", oLat);
        i.putExtra("origin_lng", oLng);
        i.putExtra("destination_lat", dLat);
        i.putExtra("destination_lng", dLng);
        i.putExtra("api_key", apiKey);
        if (mapId != null) i.putExtra("map_id", mapId);
        i.putExtra("language_code", language);
        i.putExtra("theme_mode", themeMode);
        i.putExtra("color_primary", colorPrimary);
        i.putExtra("color_on_primary", colorOnPrimary);
        i.putExtra("color_surface", colorSurface);
        i.putExtra("color_on_surface", colorOnSurface);
        startActivity(i);
        finish();
        return;
      } catch (Throwable ignored) {}

      // Fallback: show placeholder but signal SDK detected
      android.widget.TextView tv = new android.widget.TextView(this);
      tv.setText("Navigation SDK detected. Please wire Navigation view or activity.");
      tv.setTextColor(0xFF000000);
      tv.setBackgroundColor(0xFFFFFFFF);
      tv.setPadding(32, 32, 32, 32);
      root.addView(tv);
    } else {
      android.widget.TextView tv = new android.widget.TextView(this);
      tv.setText("Google Navigation SDK not available. Add dependency and keys.");
      tv.setTextColor(0xFF000000);
      tv.setBackgroundColor(0xFFFFFFFF);
      tv.setPadding(32, 32, 32, 32);
      root.addView(tv);
    }
  }
}

// Helper available-check via reflection
class GoogleMapsNativeSdkPluginHelper {}
