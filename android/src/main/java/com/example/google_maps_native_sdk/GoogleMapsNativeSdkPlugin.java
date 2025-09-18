package com.example.google_maps_native_sdk;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformViewRegistry;

/** GoogleMapsNativeSdkPlugin */
public class GoogleMapsNativeSdkPlugin implements FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {

  private Application application;
  private Activity activity;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    BinaryMessenger messenger = binding.getBinaryMessenger();
    PlatformViewRegistry registry = binding.getPlatformViewRegistry();
    registry.registerViewFactory("google_maps_native_sdk/map_view",
        new MapViewFactory(messenger));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    // no-op
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
