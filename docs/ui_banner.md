---
title: Banner de Instruções
nav_order: 15
---

# Banner de Instruções

O widget `NavInstructionBanner` exibe ícone da manobra, texto e distância restante.

## Uso básico
```dart
NavInstruction? last;

// Ao iniciar navegação
final session = await MapNavigator.start(controller: controller, options: NavigationOptions(apiKey: 'KEY', origin: o, destination: d));
session.onInstruction.listen((i) {
  setState(() => last = i);
});

// Na UI (sobreponha no mapa)
Positioned(
  top: 24,
  left: 16,
  right: 16,
  child: NavInstructionBanner(
    instruction: last,
  ),
)
```

Personalização
- `background`/`foreground`
- `iconSize`
- `textStyle`

