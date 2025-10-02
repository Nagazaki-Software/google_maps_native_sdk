package com.example.google_maps_native_sdk.car;

import androidx.annotation.NonNull;
import androidx.car.app.CarContext;
import androidx.car.app.Screen;
import androidx.car.app.model.Action;
import androidx.car.app.model.MessageTemplate;
import androidx.car.app.model.Template;

class GmnsCarScreen extends Screen {
  GmnsCarScreen(@NonNull CarContext carContext) {
    super(carContext);
  }

  @NonNull
  @Override
  public Template onGetTemplate() {
    String msg = "Google Maps Navigation SDK e credenciais devem ser configurados no app. Este é um scaffold para Android Auto.";
    return new MessageTemplate.Builder(msg)
        .setTitle("Google Maps Native SDK")
        .addAction(new Action.Builder()
            .setTitle("OK")
            .setOnClickListener(this::finish).build())
        .build();
  }
}

