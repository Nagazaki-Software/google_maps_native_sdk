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
    // Tema/estilo
    routeColor: const Color(0xFF1976D2),
    routeWidth: 6,
    // Marcador do veículo
    showVehicleMarker: true,
    vehicleIconUrl: 'asset://assets/car_arrow.png',
    vehicleIconAnchorU: 0.5,
    vehicleIconAnchorV: 0.78,
    vehicleIconDp: 48,
    vehicleRotationSource: VehicleRotationSource.course,
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
- Há detecção de desvio de rota (off-route) com throttling e re-roteamento.
- Snapping segue a polilinha; bearing usa o segmento mais próximo.
- Estilo do mapa: use `controller.setMapStyle(json)` ou `controller.setMapColor(color, dark: true/false)`.
- Ícone/marker do veículo: defina `showVehicleMarker` e `vehicleIconUrl` (suporta `asset://`, `data:`, `http(s)`), com `vehicleIconDp` para tamanho.

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
- `offRoute`: fora da rota (antes do re-roteamento)
- `rerouting`: calculando rota alternativa
- `paused`: navegação pausada (sem avançar)
- `arrived`: chegada ao destino

## Integração com Routes API v2
- Use `RoutesApi.computeRoutes` para obter alternativas, viewport e steps detalhados.
- Desenhe as rotas no mapa e selecione a ativa.
- A navegação TBT atual usa Directions (leve) para passos; a integração direta com Steps do Routes v2 pode ser adicionada conforme necessidade do app.

## SDK Navigation do Google (opcional)
Para embutir a UI nativa de navegação curva‑a‑curva do Google dentro do app (Android/iOS), é necessário ter acesso ao "Navigation SDK" do Google Maps Platform. Esse SDK não faz parte do Maps SDK padrão e requer habilitação/contrato específico na sua conta do Google Cloud. Sem esse acesso, não é possível reproduzir a UI proprietária do Google dentro do app (você ainda pode abrir o app do Google Maps por Intent/URL externo, sem customização de UI).

Caso possua acesso ao Navigation SDK e queira integrar neste plugin:
- Android: adicionar a dependência do Navigation SDK (Maven Google), criar um `PlatformView` baseado no `NavigationView/Fragment` e expor métodos no `MethodChannel` (start/stop/setTheme). O SDK oferece opções limitadas de tema/cores.
- iOS: adicionar o pod do Navigation SDK, criar um `FlutterPlatformView` que hospeda a view de navegação e encadear os callbacks/estados para o Dart.
- Em ambos, o estilo do mapa via Cloud Map ID pode ser respeitado conforme suporte do SDK.

Importante: me informe se você já tem acesso/keys do Navigation SDK. Caso não tenha, a solução TBT atual (rotas + TTS + banner) permite personalização total de cores, ícones e layout.

### API Dart (scaffold pronto)
```dart
final available = await NavigationUi.isAvailable();
if (available) {
  await NavigationUi.start(NavUiOptions(
    apiKey: 'YOUR_NAVIGATION_SDK_KEY',
    origin: const LatLng(-23.561, -46.656),
    destination: const LatLng(-23.570, -46.650),
    languageCode: 'pt-BR',
    // Tema (quando suportado pelo SDK)
    colorPrimary: const Color(0xFF0F9D58),
    colorOnPrimary: const Color(0xFFFFFFFF),
    colorSurface: const Color(0xFFF5F5F5),
    colorOnSurface: const Color(0xFF212121),
    themeMode: NavUiThemeMode.auto,
    mapId: null, // opcional
  ));
} else {
  // Fallback: usar TBT interno
}

// Para encerrar a UI nativa (ex.: ao concluir):
await NavigationUi.stop();
```
