---
title: FAQ
nav_order: 90
---

# FAQ

Perguntas frequentes sobre o uso do plugin.

## Preciso pedir permissão de localização?
Sim. O app hospedeiro deve solicitar e gerenciar permissões (ex.: com `geolocator` ou `permission_handler`). O plugin não pede a permissão por conta própria.

## Por que meu marker não gira no Web?
O marker padrão da Google Maps JS API não oferece rotação. Use ícone personalizado, AdvancedMarker ou desenhe com OverlayView conforme a necessidade.

## O `takeSnapshot()` funciona no Web?
Não. A JS API não expõe captura nativa; a função retorna `null` no Web.

## O mapa não aparece no Web
Confirme a chave `webApiKey` no `GoogleMapView` ou a inclusão do `<script>` da Maps JS API no `web/index.html`.

## Tilt/Bearing não funcionam
Aguarde `onMapLoaded` e garanta que o dispositivo/ambiente suporta essas opções. Em Web, versões antigas do Maps JS tinham suporte parcial.

