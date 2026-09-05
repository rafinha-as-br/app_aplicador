# Flows Maestro — app_aplicador

Patrimônio de teste automatizado (Android) mantido pela skill de QA
(`jira-qa-executor`). Esta é a única exceção de commit/push de todo o fluxo
Rafinha-Claude: arquivos aqui dentro podem ser commitados e enviados direto
para `develop` pela própria skill de QA — nunca código de produção.

## Estrutura

```
.maestro/
├── README.md               ← este arquivo
├── auth/
│   └── login_success.yaml  ← flow reutilizável de login (CPF/senha mockados)
├── navigation/
│   └── sem_botao_voltar_apos_login.yaml   ← GEOPRAG-125
└── applications/
    └── registrar_aplicacao_sem_erro_provider.yaml   ← GEOPRAG-126
```

- **`auth/`**: flows reutilizáveis de autenticação. Outros flows usam
  `runFlow: ../auth/login_success.yaml` em vez de duplicar os passos de
  login.
- **`navigation/`**: flows sobre navegação/roteamento (go_router).
- **`applications/`**: flows sobre o fluxo de registro de aplicação de
  produto (geolocalização, execução).

Um flow aqui é **permanente e reutilizável** entre issues futuras que
tocam no mesmo fluxo — antes de criar um novo, procure se já existe um
equivalente. Exploração pontual/ad-hoc durante uma rodada de QA (via MCP
`run`/`inspect_screen`, quando disponível) não vira arquivo aqui a menos
que valha a pena reter como regressão.

## Como rodar

Pré-requisito: emulador Android já de pé (AVD `QA - Claude`, identificador
real `QA_-_Claude`) com o app instalado (`flutter build apk --debug` +
`adb install -r`).

```bash
# Um flow específico
maestro test .maestro/auth/login_success.yaml

# Todos os flows (suíte de regressão)
maestro test .maestro/
```

## Credenciais mockadas usadas nos flows

CPF `000.000.000-00` / senha `123456` — únicas credenciais aceitas pelo
mock de autenticação (`mockUsers/mockUserSenha` em
`geoprag_modules/aplicador_app/auth/data/mock_usuarios.dart`) enquanto o
backend real não existe.

## Testabilidade — pendências conhecidas

Nenhuma até o momento (2026-09-05): os elementos usados nos flows atuais
foram localizáveis por texto visível, sem precisar de seletor relativo
(`below:`) além do já usado em `login_success.yaml` para desambiguar o
botão "Entrar" do título "Entrar" da AppBar.
