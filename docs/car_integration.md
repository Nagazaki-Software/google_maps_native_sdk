---
title: CarPlay / Android Auto
nav_order: 60
---

# Integração em Carros (Android Auto & CarPlay)

Este plugin inclui scaffolds nativos para Android Auto (projected) e CarPlay. Eles não habilitam a UI proprietária do Google automaticamente — você (ou sua conta) deve ter acesso ao Navigation SDK e configurar as credenciais. O objetivo aqui é facilitar a ligação com o mínimo de código no app host.

## Android Auto (Android for Cars App Library)

Resumo: adicionamos um `CarAppService` que apresenta um template placeholder. Você pode ligar sua navegação real usando a biblioteca `androidx.car.app`.

### O que já vem no plugin
- Dependências: `androidx.car.app:app` e `androidx.car.app:app-projected` (android/build.gradle)
- Manifest: serviço `GmnsCarAppService` declarado com categoria `navigation`
- Código base: `GmnsCarAppService`, `GmnsCarSession`, `GmnsCarScreen` (mensagem orientando a configurar credenciais/SDK)

### Como finalizar a integração
- Inclua em seu `AndroidManifest` do app final as permissões/metadados exigidos pelo Android Auto (veja a documentação do Android for Cars App Library).
- Implemente telas/template de navegação reais no `GmnsCarScreen` (ex.: `NavigationTemplate` com `Trip`s, `RoutingInfo`, etc.).
- Conecte a sua lógica de rotas (Routes API v2) e a UI/estados via os canais já existentes ou outro mecanismo adequado.
- Configure a categoria do app como navegação e siga as políticas de review do Android Auto.

## CarPlay (iOS)

Resumo: criamos um helper `GMNSCarPlayManager` com um template de lista placeholder. O host deve criar um Target de App Extension para CarPlay (`CPTemplateApplicationScene`) e usar este helper para construir o template inicial.

### O que já vem no plugin
- Podspec já linka `CarPlay` framework
- Helper em `ios/Classes/CarPlay/CarPlayManager.swift` com método `makeRootTemplate()`

### Como finalizar a integração
- No Xcode, adicione uma App Extension de CarPlay (Template Application Scene) ao seu app.
- No delegate da cena CarPlay (`CPTemplateApplicationSceneDelegate`), construa o template root chamando `GMNSCarPlayManager.makeRootTemplate()` e depois avance para seus templates de navegação reais (ex.: `CPMapTemplate`, `CPTripPreviewTextConfiguration`).
- Configure capabilities de CarPlay e entitlements no app.
- Integre sua lógica de rotas e UI do Navigation SDK conforme suporte.

## Navigation SDK (opcional)

- O plugin já fornece a API Dart `NavigationUi` (Android/iOS) para iniciar a UI nativa do Navigation quando disponível e habilitada na sua conta. Veja `docs/navegacao.md`.
- Sem o Navigation SDK, utilize a navegação TBT interna (polilinha + TTS + banner), que é fortemente customizável e funciona em todas as plataformas (fora do ambiente veicular).

## Credenciais e chaves

- As chaves (API key, Map ID, etc.) continuam sendo fornecidas pelo app host. O plugin apenas expõe os pontos de integração.
- Android: configure as chaves do Maps/Navigation nos recursos/manifest do app e permissões de localização necessárias.
- iOS: forneça a key do Google Maps/Navigation (via `NavigationUi.start`) e configure as capabilities (CarPlay, Background Modes se aplicável).
