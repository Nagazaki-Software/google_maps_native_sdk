---
title: Bússola e Áudio
nav_order: 16
---

# Bússola / Heading e Áudio (TTS)

- Heading do dispositivo com suavização exponencial e regras de baixa velocidade.
- Foco de áudio/ducking durante instruções de voz.

## Heading (compass / rotation vector)
- A navegação usa o heading do smartphone abaixo de `lowSpeedAutoRotateKmh` (padrão 3 km/h) e troca para `course` do GPS acima disso.
- Suavização: `headingFilterAlpha` (0..1) para reduzir jitter e tratar wrap 0/360.
- iOS: `CLHeading` (trueHeading quando disponível, fallback para magneticHeading).
- Android: Sensor `TYPE_ROTATION_VECTOR` (orientação absoluta).

Habilite via `NavigationOptions`:
```dart
NavigationOptions(
  // ...
  followBearing: true,
  useDeviceHeading: true,
  lowSpeedAutoRotateKmh: 3.0,
  headingFilterAlpha: 0.25,
)
```

Permissões:
- iOS: inclua `NSLocationWhenInUseUsageDescription` (e `NSLocationAlwaysAndWhenInUseUsageDescription` se necessário). Para background, habilite `UIBackgroundModes=location` no app host.
- Android: o heading não exige permissão adicional; o `course` vem de localização (`ACCESS_FINE_LOCATION`).

## Áudio (TTS) com ducking
- iOS: o plugin configura categoria `playback` com `duckOthers` quando `iosDuckOthers=true`.
- Android: solicita `AudioFocus` (`USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`) quando `androidRequestAudioFocus=true`.
- Interrupção de fala: `interruptOnNewInstruction=true` para interromper a fala atual ao chegar uma nova instrução.

Exemplo:
```dart
final session = await MapNavigator.start(
  controller: controller,
  options: NavigationOptions(
    apiKey: 'KEY',
    origin: const LatLng(-23.561, -46.656),
    destination: const LatLng(-23.570, -46.650),
    language: 'pt-BR',
    followBearing: true,
    useDeviceHeading: true,
    lowSpeedAutoRotateKmh: 3,
    headingFilterAlpha: 0.25,
    iosDuckOthers: true,
    androidRequestAudioFocus: true,
    interruptOnNewInstruction: true,
  ),
);
```

