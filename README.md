# app_aplicador

Aplicativo **Flutter Mobile** do Geoprag destinado aos **Aplicadores de campo da Prefeitura de Gaspar**, usado no dia a dia do combate à dengue diretamente no território.

## O que é

O `app_aplicador` é o app móvel usado pelos agentes em campo para registrar aplicações de produtos larvicidas/inseticidas, marcar pontos de aplicação georreferenciados, controlar o recebimento de insumos e denunciar focos de dengue — inclusive **offline**, já que a operação em campo nem sempre tem conexão.

Este repositório contém apenas a **aplicação Flutter Mobile** (o "shell" do app: navegação, integração com a API e composição das telas). As telas, widgets e regras de cada módulo funcional vêm do pacote compartilhado [`geoprag_modules`](../geoprag_modules), consumido via dependência local (`path: ../../geoprag_modules/geoprag_modules`).

## Funcionalidades (via `geoprag_modules/aplicador_app`)

- **Autenticação** — login do aplicador, com camadas adicionais de segurança (ver seção abaixo).
- **Pontos de aplicação** — marcação e visualização de pontos georreferenciados.
- **Registro de aplicações** — telas de geolocalização, execução e informação da aplicação realizada.
- **Inventário** — recebimento de produtos e consulta de insumos disponíveis.
- **Denúncias** — cadastro de focos de dengue, dashboard de denúncias e conteúdo educativo.

## Arquitetura e decisões relevantes

- Assim como o `app_administrador`, é um **cliente magro**: regras de negócio e segurança residem na API central (`geoprag_api`).
- Autenticação em **5 camadas**, pensada para uso em campo e sem conexão: credenciais → PIN/biometria local → token (validade 30 dias) → par de chaves assimétricas por dispositivo (assinatura de desafio a cada requisição) → revogação remota pelo administrador. O fluxo completo, decisões de implementação em aberto (ex.: geração de chaves em Dart puro vs. Keystore/Secure Enclave nativo) e riscos estão documentados em [`docs/autenticacao.md`](docs/autenticacao.md).
- **Suporte offline**: registros feitos sem conexão ficam pendentes de sincronização (Sqflite/Hive) e são reenviados automaticamente quando a conexão retorna. Após expirado (30 dias), o token ainda permite uma única confirmação de aplicação em andamento antes de exigir novo login.
- Status atual: **planejamento pré-implementação** — o `lib/` contém apenas o `main.dart` padrão gerado pelo `flutter create`; a lógica de autenticação e integração com a API ainda não foi implementada.

## Estrutura

```
app_aplicador/
  app_aplicador/     # projeto Flutter (lib/, android/, ios/, web/, etc.)
  docs/
    autenticacao.md  # especificação do módulo de autenticação (5 camadas)
```

## Dependências principais

- Flutter (SDK `^3.9.2`)
- `geoprag_modules` (path dependency, pacote compartilhado de UI e regras de módulos)

## Como rodar

```bash
cd app_aplicador
flutter pub get
flutter run
```
