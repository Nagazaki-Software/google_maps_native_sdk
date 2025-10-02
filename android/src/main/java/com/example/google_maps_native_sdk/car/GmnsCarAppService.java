package com.example.google_maps_native_sdk.car;

import androidx.annotation.NonNull;
import androidx.car.app.CarAppService;
import androidx.car.app.Session;
import androidx.car.app.Screen;
import androidx.car.app.validation.HostValidator;
import android.content.Intent;

/**
 * Android Auto (projected) scaffold service. This is a minimal implementation
 * that shows a placeholder template instructing the developer to wire the
 * real navigation experience using the Android for Cars App Library.
 */
public class GmnsCarAppService extends CarAppService {

  @NonNull
  @Override
  public HostValidator createHostValidator() {
    // For development, allow all hosts. In production, restrict to known hosts.
    return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR;
  }

  @NonNull
  @Override
  public Session onCreateSession() {
    return new GmnsCarSession();
  }
}

