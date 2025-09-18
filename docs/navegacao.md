---
title: Navegação (TBT)
nav_order: 7
---

# Navegação leve (Turn‑by‑Turn)

Navegação com Directions API, TTS para instruções e câmera seguindo o usuário. Não é um SDK completo de navegação; é leve e customizável para apps de mobilidade.

## Iniciar sessão
```dart
final session = await MapNavigator.start(
  controller: controller,
  options: NavigationOptions(
    apiKey: 'YOUR_DIRECTIONS_API_KEY',
    origin: const LatLng(-23.561, -46.656),
    destination: const LatLng(-23.570, -46.650),
    language: 'pt-BR',
    voiceGuidance: true,
    cameraZoom: 17,
    cameraTilt: 45,
    followBearing: true,
  ),
);
```

## Eventos
```dart
session.onProgress.listen((p) {
  // ETA (aprox) e distância restante em metros
});
session.onInstruction.listen((i) {
  // Texto da manobra atual e distância
});
session.onState.listen((s) {
  // navigating / offRoute / rerouting
});
```

## Controles
```dart
await session.recenter(); // overview atual
await session.overview(); // alias
await session.stop();     // encerra navegação (remove polyline)
```

## Observações
- O app deve gerenciar permissões de localização.
- TTS usa `flutter_tts`; ajuste `ttsRate/ttsPitch/ttsVoice` conforme a plataforma.
- Há detecção simples de desvio de rota e re-roteamento com throttle.

