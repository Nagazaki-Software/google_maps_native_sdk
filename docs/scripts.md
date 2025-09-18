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

Gerar referência de API (dartdoc) e hospedar em `docs/api/` (opcional):
```
dart pub global activate dartdoc
dart doc -o docs/api
```
Depois faça push e a pasta ficará disponível em `https://<seu-usuario>.github.io/<repo>/api/`.

