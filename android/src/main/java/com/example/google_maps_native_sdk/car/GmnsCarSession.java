package com.example.google_maps_native_sdk.car;

import androidx.annotation.NonNull;
import androidx.car.app.Session;
import androidx.car.app.Screen;
import android.content.Intent;

class GmnsCarSession extends Session {
  @NonNull
  @Override
  public Screen onCreateScreen(@NonNull Intent intent) {
    return new GmnsCarScreen(getCarContext());
  }
}

