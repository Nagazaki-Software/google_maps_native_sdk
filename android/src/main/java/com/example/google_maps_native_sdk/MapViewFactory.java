package com.example.google_maps_native_sdk;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

class MapViewFactory extends PlatformViewFactory {
  private final BinaryMessenger messenger;

  MapViewFactory(BinaryMessenger messenger) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
  }

  @Override
  @SuppressWarnings("unchecked")
  public PlatformView create(@NonNull Context context, int viewId, Object args) {
    Map<String, Object> creationParams = (Map<String, Object>) args;
    return new MapViewPlatformView(context, messenger, viewId, creationParams);
  }
}

