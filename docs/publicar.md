---
title: Publicar no GitHub Pages
nav_order: 100
---

# Como publicar este site

Opção simples (sem Actions):
1) Faça push do branch `main` com esta pasta `docs/`.
2) No GitHub, acesse Settings → Pages.
3) Em Source, escolha `Deploy from a branch`.
4) Selecione `Branch: main` e `Folder: /docs`.
5) Salve. Seu site ficará disponível em `https://<seu-usuario>.github.io/<repo>/`.

Opcional (Actions/gh-pages):
- Se preferir publicar em um branch dedicado, você pode usar uma Action de Pages. Para este projeto, usar a pasta `docs/` é suficiente.

