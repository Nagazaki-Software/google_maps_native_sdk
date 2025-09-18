---
title: FlutterFlow Helpers
nav_order: 20
---

FlutterFlow Helpers (Actions)

Resumo
- `GmnsNavHub` facilita ações personalizadas no FlutterFlow (um único ponto para controlar mapa e navegação).
- Crie ações que chamem os métodos do hub, via wrappers no seu app.

API rápida
```dart
// No onMapCreated do seu widget de mapa
GmnsNavHub.setController(controller);

// Rotas (alternativas) e desenho
await GmnsNavHub.computeRoutesAndDraw(
  apiKey: 'KEY',
  origin: const LatLng(-23.561, -46.656),
  destination: const LatLng(-23.570, -46.650),
);

// Trocar rota ativa
await GmnsNavHub.chooseActiveRoute(0);

// Navegação (TBT)
await GmnsNavHub.startNavigation(
  apiKey: 'KEY',
  origin: const LatLng(-23.561, -46.656),
  destination: const LatLng(-23.570, -46.650),
);
await GmnsNavHub.stopNavigation();

// Centralizar/Overview durante navegação
await GmnsNavHub.recenter();
await GmnsNavHub.overview();
```

Como ligar no FlutterFlow
1) Adicione este pacote como “Custom Package”.
2) Na tela com o mapa, exponha `onMapCreated` e chame `GmnsNavHub.setController(controller)`.
3) Crie “Custom Actions” que chamem os métodos do hub (crie wrappers no app, se preferir).
4) Para ETA/instruções, escute os streams no app e exponha como estado para a UI.

Observações
- O hub armazena uma única instância de controller/sessão. Para múltiplos mapas, estenda a classe gerenciando IDs.
- Para limites de velocidade/faixas/incidentes dinâmicos, integre APIs do Google e repasse para sua UI.

