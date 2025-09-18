---
title: Scripts Úteis
nav_order: 50
---

# Scripts / Comandos úteis

Ambiente Flutter:
```
flutter pub get
flutter run -d android
flutter run -d ios
flutter config --enable-web
flutter run -d chrome
flutter build web --release
flutter clean
```

Gerar referência de API (dartdoc) local (opcional):
```
dart pub global activate dartdoc
dart doc -o build/api
```
Os arquivos são gerados em `build/api/` no seu ambiente local.

