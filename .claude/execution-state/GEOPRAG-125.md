Estado: EM_EXECUÇÃO

Issue: GEOPRAG-125 — Corrigir botão de voltar exibido indevidamente após login no app aplicador
Repo: app_aplicador (não geoprag_modules — o campo "Link para Github Issue" da
issue aponta para geoprag_modules#58, mas a investigação de código confirmou
que a causa raiz está na implementação concreta do navigator, que vive aqui)

Objetivo: após o login, a App Bar de /ponto exibe um botão de voltar indevido.

Causa raiz encontrada: `AplicadorGoRouterNavigator.toPonto()`
(lib/navigation/aplicador_go_router_navigator.dart) usa
`_router.pushReplacement('/ponto')`, que só substitui o topo da pilha — a
LandingScreen ('/') permanece embaixo, então o GoRouter considera que dá pra
voltar (AppBar mostra o botão). O fluxo de esqueci-senha já usa o padrão
correto (`toLoginResetStack()` → `_router.go('/login')`, reset completo).

Fix: trocar `toPonto()` para `_router.go('/ponto')`. Escopo restrito a
`toPonto()` (chamado após login e após concluir o fluxo de aplicação) —
não mexer nos demais métodos `pushReplacement` (toInventario, toDenuncias
etc.), fora do escopo desta issue.

Próxima ação: aplicar o fix, rodar flutter analyze + testes, autorevisão/code
review, commit.
