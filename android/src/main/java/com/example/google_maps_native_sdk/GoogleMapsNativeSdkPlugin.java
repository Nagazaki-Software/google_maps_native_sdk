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
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    try {
      if (headingChannel != null) headingChannel.setStreamHandler(null);
    } catch (Throwable ignored) {}
    headingChannel = null;
    audioChannel = null;
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
