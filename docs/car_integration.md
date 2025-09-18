---
title: CarPlay / Android Auto
nav_order: 60
---

# CarPlay / Android Auto

Integração com CarPlay e Android Auto depende de frameworks/plataformas específicas e políticas das lojas. Este plugin fornece o mapa e navegação em Flutter, mas a integração ao sistema do carro requer camadas adicionais.

Pontos importantes
- CarPlay: exige iOS, entitlement específico, categorias de app elegíveis e uso do framework CarPlay (UI baseada em templates Apple, não mapas customizados arbitrários). Consultar documentação Apple.
- Android Auto: apps de navegação precisam seguir o modelo de templates do Android for Cars App Library. O repositório inclui um exemplo de referência em `example/android-auto-sample/README.md`.
- Este plugin pode prover dados/rotas e renderização em vistas Flutter do app principal. Para head units, o fluxo comum é usar os templates nativos (CarPlay/Android Auto) e alimentar com rotas/instruções (texto/ícones) vindos do app, mantendo políticas das plataformas.

Recomendação
- Use o SDK de templates de cada plataforma para UI no painel do carro e reutilize o motor de rotas/navegação (Routes v2 + TTS) do app para calcular rotas, instruções e ETA. Mantenha a sincronização de estado entre a sessão principal e a interface do veículo.

