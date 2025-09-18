---
title: Troubleshooting
nav_order: 91
---

# Troubleshooting

## Mapa em branco (Android/iOS)
- Verifique a chave de API correta e se o pacote do app está autorizado no console do Google.
- Confirme permissões e serviços Google Play atualizados.

## Erro ao registrar PlatformView no Web
- Atualize o Flutter para versão que suporte `HtmlElementView` padrão.
- Evite dependências que troquem o registro do PlatformView.

## TTS não fala (iOS)
- Configure `AVAudioSession` no app, ajuste `ttsRate/ttsPitch` e garanta volume/áudio ativos.

## Rotas não retornam
- Confirme as APIs habilitadas (Directions API/Routes API) e restrições de chave.

