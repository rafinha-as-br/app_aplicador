# app_aplicador

Aplicativo **Flutter Mobile** do Geoprag destinado aos **Aplicadores de campo da Prefeitura de Gaspar**, usado no dia a dia do combate à dengue diretamente no território.

## O que é

O `app_aplicador` é o app móvel usado pelos agentes em campo para registrar aplicações de produtos larvicidas/inseticidas, marcar pontos de aplicação georreferenciados, controlar o recebimento de insumos e denunciar focos de dengue — inclusive **offline**, já que a operação em campo nem sempre tem conexão.

Este repositório contém apenas a **aplicação Flutter Mobile** (o "shell" do app: navegação, integração com a API e composição das telas). As telas, widgets e regras de cada módulo funcional vêm do pacote compartilhado [`geoprag_modules`](../geoprag_modules), consumido via dependência git (branch `develop`) — ver [Desenvolvimento local com `geoprag_modules`](#desenvolvimento-local-com-geoprag_modules) abaixo.

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
- `geoprag_modules` (git dependency, apontando pra `develop` — pacote compartilhado de UI e regras de módulos)

## Como rodar

```bash
cd app_aplicador
flutter pub get
flutter run
```

## Desenvolvimento local com `geoprag_modules`

O `pubspec.yaml` aponta `geoprag_modules` como dependência git (`ref: develop`), não path local — isso garante que CI e todo mundo no time sempre resolvem a mesma versão de verdade, publicada no repositório.

Se você está desenvolvendo uma mudança em `geoprag_modules` em paralelo e precisa testá-la aqui **antes de commitar/subir** essa mudança, troque temporariamente a entrada no `pubspec.yaml`:

```yaml
dependencies:
  geoprag_modules:
    path: ../../geoprag_modules/geoprag_modules_project
```

**Nunca commite essa troca.** A pipeline de CI falha (job `guard`) se detectar `path:` na entrada de `geoprag_modules` — desfaça antes de dar push.

## Convenção de branch

```
{tipo}/{CHAVE-DA-ISSUE}-claude
```

Exemplo: `feat/GEOPRAG-24-claude`. A chave da issue no nome é o que permite a integração nativa GitHub-Jira detectar automaticamente o vínculo entre branch/commit/PR e a issue no Jira. `develop` é a branch de integração (é para onde o merge acontece depois que a pipeline passa); `main` fica reservada para produção/release.

## CI (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

- **Triggers**: Pull Request para `develop`/`main`; push em `develop`
- **Job `Guard - geoprag_modules deve ser git dependency`**: falha se detectar dependência via path local (`../`) no `pubspec.yaml` — pega de volta qualquer troca de dev local esquecida antes do push
- **Job `Analyze, test & build (web + apk)`** (depende do guard): checkout → Flutter 3.35.5 → `flutter pub get` → `flutter analyze --no-fatal-infos` → `flutter test` → `flutter build web` → `flutter build apk`
- **Gates obrigatórios (bloqueiam merge)**: os dois jobs acima (guard sempre; no segundo, `flutter analyze` — erros e warnings, infos não bloqueiam —, `flutter build web` e `flutter build apk`)
- **Não bloqueia ainda**: `flutter test` roda e reporta, mas não derruba o job (`continue-on-error: true`). Motivo: `test/widget_test.dart` hoje é só o stub vazio gerado pelo `flutter create` — 0 testes reais (`flutter test` retorna "No tests found"). Assim que existirem testes de verdade, remover o `continue-on-error` e marcar `test` como check obrigatório na branch protection.
- **Builda web e APK**: o alvo real de produção é mobile (Android), mas o build web é mantido porque a skill de QA valida via navegador — os dois caminhos precisam continuar saudáveis. iOS fica de fora por enquanto (custo/complexidade de runner `macos-latest` não se justifica ainda).
- **Branch protection na `develop`**: ativa, exige os dois jobs acima passando + branch atualizada com a `develop` antes do merge (`strict: true`). `enforce_admins` está desligado — o dono do repo ainda consegue fazer bypass numa emergência, mas o fluxo normal (PR + merge automatizado) sempre passa pelos checks.

## Release & Versionamento

Ciclo de entrega separado do dia a dia de merges em `develop` — ver [Release & Versionamento](https://rafinha84dev.atlassian.net/wiki/spaces/CS1/pages/44335153) no Confluence para o conceito completo. Executado sob demanda por `jira-release-executor`, nunca automaticamente.

- **Versão**: `version:` no `pubspec.yaml` (`X.Y.Z+build`, SemVer). Hoje em `0.1.0+1` — projeto em desenvolvimento inicial.
- **Changelog**: [`CHANGELOG.md`](CHANGELOG.md), formato Keep a Changelog.
- **Estratégia de branch**: sem branch de release dedicada por enquanto — `develop → main` direto via PR quando uma release for cortada. `release/X.Y.Z` fica reservada pra quando o projeto precisar de uma janela de estabilização (Release Candidate) antes do merge pra `main`.
- **Pipeline**: [`.github/workflows/release.yml`](.github/workflows/release.yml), trigger em push de tag `v*`. Roda `analyze` + `test` de novo — aqui **sem** `continue-on-error` (release.yml responde "está pronto pra virar versão oficial?", régua mais rígida que o `ci.yml`) — builda `flutter build web --release` e `flutter build apk --release`, anexa os dois como artifact na GitHub Release, criada com notas geradas automaticamente.
- **Atenção**: como hoje não existem testes reais aqui (0 testes, ver seção CI), o step `flutter test` do `release.yml` **sempre falha** ("No tests found") — nenhuma release consegue ser cortada até existir pelo menos 1 teste real. Intencional: reflete a régua mais rígida do ciclo de release.
- **Branch protection na `main`**: ativa, exige o job `Validate, build & publish release` passando antes de qualquer merge.
