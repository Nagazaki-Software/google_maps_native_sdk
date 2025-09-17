package com.example.google_maps_native_sdk;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformViewRegistry;

/** GoogleMapsNativeSdkPlugin */
public class GoogleMapsNativeSdkPlugin implements FlutterPlugin {

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
}

