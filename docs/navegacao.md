---
title: Navegação (TBT)
nav_order: 7
---

# Navegação (Turn‑by‑Turn)

SDK de navegação com voz, re‑roteamento, snapping na rota, simulação e eventos para UI. Usa polylines do Google Directions/Routes e TTS para instruções.

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
    // Novos recursos
    approachSpeakMeters: const [400, 150, 30, 10],
    arrivalThresholdMeters: 25,
    snapToRoute: true,
    mapMatchingToleranceMeters: 30,
    rerouteOnOffRoute: true,
    // Simulação (opcional, para demos/tests)
    // simulationSpeedKmh: 40,
    // Alertas de velocidade (opcional)
    // speedAlertsEnabled: true,
    // speedLimitKmh: 50, // estático
    // speedLimitProvider: (pos) async => await minhaApiDeLimites(...),
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
  // navigating / offRoute / rerouting / paused / arrived
});
```

## Controles
```dart
await session.recenter(); // overview atual
await session.overview(); // alias
await session.pause();    // pausa (stream GPS ou simulação)
await session.resume();   // retoma
await session.stop();     // encerra navegação (remove polyline)
```

## Observações
- O app deve gerenciar permissões de localização (quando não está em modo simulado).
- TTS usa `flutter_tts`; ajuste `ttsRate/ttsPitch/ttsVoice` conforme a plataforma.
- Há detecção de desvio de rota (off‑route) com throttling e re‑roteamento.
- Snapping segue a polilinha; bearing usa o segmento mais próximo.

## Routes API v2 (passos localizados)
Para usar os Steps da Routes API v2 diretamente na navegação (instruções e maneuvers localizados):
```dart
final session = await MapNavigator.start(
  controller: controller,
  options: NavigationOptions(
    apiKey: 'YOUR_ROUTES_API_KEY',
    origin: const LatLng(-23.561, -46.656),
    destination: const LatLng(-23.570, -46.650),
    language: 'pt-BR',
    useRoutesV2: true,
    intermediates: const [
      Waypoint(location: LatLng(-23.566, -46.653), via: true, sideOfRoad: true),
    ],
  ),
);
```

## Controles de simulação
Durante navegação simulada, é possível alterar a velocidade:
```dart
if (session.isSimulating) {
  await session.setSimulationSpeed(60); // km/h
}
```

## Opções (NavigationOptions)
- `approachSpeakMeters`: limiares para anunciar instruções (ex.: [400, 150, 30, 10])
- `arrivalThresholdMeters`: distância para considerar chegada ao destino (ex.: 25m)
- `snapToRoute`: corrige posição para a polilinha mais próxima da rota
- `mapMatchingToleranceMeters`: tolerância do snapping (aprox.)
- `rerouteOnOffRoute`: ativa re‑roteamento quando fora da rota por um limiar
- `simulationSpeedKmh`: ativa modo simulado (sem GPS) à velocidade informada
- `speedAlertsEnabled`: ativa eventos de alerta de velocidade
- `speedLimitKmh`: limite estático (fallback)
- `speedLimitProvider(position)`: provedor dinâmico opcional de limite (chamado periodicamente)

## Alertas de velocidade (opcional)
```dart
final session = await MapNavigator.start(
  controller: controller,
  options: NavigationOptions(
    // ...
    speedAlertsEnabled: true,
    // limite estático
    speedLimitKmh: 50,
    // OU dinâmico via provider
    speedLimitProvider: (pos) async {
      // Chame sua API de limites aqui e retorne km/h
      return 60;
    },
  ),
);

session.onSpeedAlert.listen((a) {
  if (a.overLimit) {
    // mostrar aviso visual/sonoro
  }
});
```

## Simulação (demo/testes)
```dart
final session = await MapNavigator.start(
  controller: controller,
  options: NavigationOptions(
    // ...
    simulationSpeedKmh: 40, // percorre a rota sem depender de GPS
  ),
);
```

## Estados
- `navigating`: navegando normalmente
- `offRoute`: fora da rota (antes do re‑roteamento)
- `rerouting`: calculando rota alternativa
- `paused`: navegação pausada (sem avançar)
- `arrived`: chegada ao destino

## Integração com Routes API v2
- Use `RoutesApi.computeRoutes` para obter alternativas, viewport e steps detalhados.
- Desenhe as rotas no mapa e selecione a ativa.
- A navegação TBT atual usa Directions (leve) para passos; a integração direta com Steps do Routes v2 pode ser adicionada conforme necessidade do app.
