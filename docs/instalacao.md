---
title: Instalação & Chaves
nav_order: 2
---

# Instalação & Configuração de Chaves

## Dependências
```
flutter pub add google_maps_native_sdk
```

Permissões de localização devem ser tratadas pelo app (ex.: `geolocator`/`permission_handler`).

## Android
- Insira a chave no `AndroidManifest.xml` (app):
```
<application>
  <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_ANDROID_API_KEY"/>
</application>
```
- Garanta `minSdkVersion` 21+.

## iOS
- Forneça a chave no `AppDelegate` (Swift) ou Info.plist:
```
GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
```
- Configure permissões de localização e áudio (para TTS) conforme necessário.

## Web
Escolha UMA das opções:
- Passar `webApiKey` no `GoogleMapView`;
- OU injetar o script no `web/index.html`:
```
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_MAPS_JS_API_KEY&libraries=geometry&v=weekly"></script>
```

## Dicas
- Use `await controller.onMapLoaded` para só adicionar overlays pesados após o mapa estar pronto.
- Para mini-mapas Android, experimente `liteMode: true` no `GoogleMapView`.

