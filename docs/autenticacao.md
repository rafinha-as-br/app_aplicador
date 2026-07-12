# Autenticação — App Aplicador (Flutter Mobile)

> Escopo: implementação **front-end** do módulo de autenticação no `app_aplicador`, usado pelos Aplicadores de campo da Prefeitura de Gaspar.
> Fonte de verdade das regras de negócio e segurança (não duplicar, apenas referenciar): Confluence — *Arquitetura da Solução*, *Módulo Autenticação - Segurança de acesso para Aplicadores*, *Especificação técnica: garantia de uso único do token expirado*.
> Status: **planejamento pré-implementação** — não há código de autenticação no repositório ainda (`lib/` contém apenas o `main.dart` padrão do `flutter create`).

---

## 1. Contexto e diferença em relação ao App Administrador

O `app_aplicador` compartilha os mesmos princípios de segurança do `app_administrador` (credenciais, token, revogação), mas adiciona um contexto que muda bastante o desenho do front-end: **o Aplicador opera em campo, muitas vezes sem conexão**. Por isso a arquitetura de autenticação aqui tem duas camadas a mais que o app web não tem: **PIN/biometria local** e **par de chaves assimétricas por dispositivo**.

Assim como o `app_administrador`, este app é um cliente magro: a validação de credenciais, geração/validação de token e todas as regras de expiração são responsabilidade do backend (`geoprag_api`). Este documento define como o front-end Flutter deve implementar sua parte do contrato.

## 2. As 5 camadas de segurança e a responsabilidade do front-end em cada uma

| # | Camada | O que é (regra de negócio, já definida) | Responsabilidade do front-end |
|---|---|---|---|
| 1 | Credenciais | Login e senha, enviados no primeiro acesso ao dispositivo | Tela de login + chamada à API |
| 2 | PIN/Biometria | Confirma que quem está usando o dispositivo é o dono, nos acessos seguintes | Integração com biometria/PIN nativos do SO antes de liberar uso do token salvo |
| 3 | Token | Token criptografado, validade de 30 dias, renovado a cada novo login | Armazenamento seguro local + reenvio em cada requisição |
| 4 | Par de chaves assimétricas | Gerado no dispositivo; a chave pública é associada ao token no backend; cada requisição prova posse do dispositivo assinando um desafio com a chave privada | Geração e guarda segura do par de chaves; assinatura do desafio a cada requisição |
| 5 | Revogação de sessão | Um administrador pode revogar o login de um Aplicador no portal web | Reagir a uma sessão revogada exigindo login manual (credenciais) novamente |

As seções seguintes detalham a implementação de cada camada relevante para o front-end (a camada 1 é uma tela de login comum e não precisa de detalhamento extra).

## 3. Camada de PIN/Biometria

Implementação recomendada: pacote `local_auth` (biometria/PIN nativo do dispositivo via Android BiometricPrompt / iOS LocalAuthentication).

Regra de uso (conforme Confluence): a biometria/PIN é solicitada **antes de liberar o uso do token salvo**, tanto no primeiro login (logo após inserir credenciais, para ativação) quanto em todo login subsequente no mesmo dispositivo. Ou seja, o token nunca é lido do secure storage sem essa checagem passar antes.

## 4. Camada de token + armazenamento seguro

- Pacote recomendado: `flutter_secure_storage` (usa Keychain no iOS e Keystore/EncryptedSharedPreferences no Android).
- O que é armazenado: o token (30 dias) e, dependendo da decisão da seção 5, a chave privada do par assimétrico.
- Renovação: a cada novo login manual (com credenciais) no mesmo dispositivo, o token antigo é descartado e substituído.

## 5. Camada de par de chaves assimétricas — decisão de implementação em aberto

Esta é a camada com maior impacto de esforço e a que exige uma decisão explícita antes de codar. A regra de negócio (Confluence) é clara sobre o comportamento — "a cada requisição, a chave pública é usada para validar o desafio assinado pela chave privada" — mas não define **onde e como** a chave privada deve ser gerada e guardada. Duas abordagens possíveis:

**Opção A — Criptografia em Dart puro** (ex.: pacote `cryptography` ou `pointycastle`)
- Vantagem: mais simples de implementar e testar, portável entre plataformas.
- Desvantagem: a chave privada, mesmo guardada via `flutter_secure_storage`, existe como bytes que passam pela memória do processo Dart/Flutter. Não é "non-extractable" a nível de hardware.

**Opção B — Keystore/Secure Enclave nativo** (Android Keystore com chave gerada com `setUserAuthenticationRequired`, iOS Secure Enclave)
- Vantagem: a chave privada é gerada e usada **dentro do hardware seguro do dispositivo**, nunca existindo como bytes acessíveis ao app — a operação de assinatura acontece dentro do enclave, com biometria como pré-condição nativa.
- Desvantagem: exige código nativo por plataforma (ou um plugin que já abstraia isso — vale pesquisar antes de escrever código nativo próprio) e mais esforço de implementação/teste.

**Recomendação:** dado que este token, após 30 dias, se torna a única prova de identidade capaz de confirmar uma aplicação química em campo mesmo offline (ver seção 7), a Opção B é a que efetivamente entrega a garantia de segurança que a arquitetura descreve ("o mesmo dispositivo que gerou o token"). A Opção A é aceitável como primeira versão/MVP, mas deve ser tratada como débito técnico documentado, não como decisão definitiva — sugere-se isolar essa camada atrás de uma interface (`DeviceKeyManager` ou similar) para permitir trocar a implementação sem afetar o restante do app.

## 6. Fluxos de login (client-side)

**Primeiro login no dispositivo:**

1. Usuário insere login e senha.
2. App solicita ativação de PIN/Biometria (`local_auth`).
3. App gera o par de chaves assimétricas (local, conforme decisão da seção 5).
4. App envia credenciais + chave pública para a API.
5. API valida credenciais, associa a chave pública ao token gerado, retorna o token.
6. App salva token (e chave privada, se Opção A) no secure storage.

**Login subsequente (mesmo dispositivo, com "lembrar login" ativo):**

1. App solicita PIN/Biometria.
2. App recupera token e chave (pública/privada) do secure storage.
3. App assina um desafio com a chave privada e envia token + chave pública + assinatura à API.
4. API valida a assinatura e retorna um novo token.

> ⚠️ **Ponto em aberto:** o passo 3 pressupõe que a API forneça um **desafio (nonce)** para ser assinado — isso é implícito na regra de negócio ("desafio assinado pela chave privada"), mas **não há endpoint definido** para obter esse desafio. Isso é bloqueante para implementar o login subsequente e precisa ser resolvido com quem for implementar o backend (ver seção 8).

## 7. Funcionamento offline e a regra do "token de uso único" após 30 dias

Pontos que o front-end precisa implementar, além do que a API garante:

- **Fila local de operações offline:** registros de aplicação feitos sem conexão ficam com status "Pendente de Sincronização" (Sqflite ou Hive, conforme *Arquitetura da Solução*) e são reenviados automaticamente quando a conexão voltar.
- **Réplica local da regra de "modo restrito":** passados os 30 dias de validade do token, o backend só aceita uma única operação com aquele token — a confirmação de aplicação química — e descarta o token após o uso (via `jti`, ver *Especificação técnica: garantia de uso único do token expirado*). A fonte de verdade dessa regra é sempre o backend, mas o app deve replicar essa checagem localmente **apenas para UX**: evitar que o Aplicador preencha uma tela inteira de um formulário que será rejeitado, avisando de forma antecipada ("seu acesso expirou; você ainda pode confirmar a aplicação em andamento, mas precisará fazer login novamente para continuar usando o app").
- **Tratamento da resposta de rejeição por token já consumido:** se o backend rejeitar por `jti` já usado, exibir mensagem clara indicando que é necessário novo login — não é um erro genérico de rede.

## 8. Definição da API — endpoints

> ⚠️ Assim como no `app_administrador`, a página *API - Autenticação* no Confluence descreve comportamento, não contrato formal. A proposta abaixo cobre os endpoints necessários para os fluxos acima; os itens marcados "a confirmar" são bloqueantes.

| Endpoint | Método | Request | Response (sucesso) | Observações |
|---|---|---|---|---|
| `/auth/login` | POST | `{ "login": string, "senha": string, "public_key": string }` | `200` → `{ "token": string, "usuario": {...} }` | Primeiro login no dispositivo. Token válido por 30 dias. |
| `/auth/challenge` | GET | — | `200` → `{ "nonce": string }` | **A confirmar.** Necessário para o login subsequente (seção 6) — hoje não documentado. |
| `/auth/login-device` | POST | `{ "token": string, "public_key": string, "signed_nonce": string }` | `200` → `{ "token": string }` (renovado) | **A confirmar** (nome e existência do endpoint). Login subsequente, sem reenviar credenciais. |
| `/aplicacoes/confirmar` (ou equivalente do módulo de aplicação química) | POST | payload da aplicação + token (mesmo fora dos 30 dias) | `200` | O backend precisa tratar esse endpoint especificamente como exceção ao bloqueio geral de token expirado — confirmar com o backend que essa exceção está implementada exatamente nesta rota. |
| Revogação manual de sessão (feita pelo administrador no `app_administrador`) | **a confirmar** | — | — | Não é chamada pelo `app_aplicador` diretamente, mas o comportamento esperado (próxima requisição do Aplicador cai em 401/revogado) precisa estar consistente entre os dois apps. |

## 9. Estrutura sugerida no projeto

```
lib/
  features/
    auth/
      data/          # AuthRemoteDataSource, DTOs
      domain/         # AuthRepository (interface), entidades
      presentation/   # LoginPage, controllers/state
  core/
    device_security/  # DeviceKeyManager (geração de chaves, assinatura), SecureStorage wrapper, integração local_auth
    http/              # cliente HTTP + interceptor de 401/revogação
```

Isolar `device_security` como módulo próprio é o que permite trocar a Opção A pela Opção B (seção 5) mais adiante sem reescrever o restante do fluxo de autenticação.

## 10. Dependências e riscos em aberto

1. **Mecanismo de desafio (challenge signing)** — endpoint não documentado, bloqueante para o login subsequente (seção 6/8).
2. **Decisão sobre geração do par de chaves** (Opção A vs B, seção 5) — impacta diretamente o esforço de implementação e os pacotes/plugins necessários.
3. **Rota específica para confirmação de aplicação química com token restrito** — precisa de confirmação de que o backend já implementa a exceção descrita em *Especificação técnica: garantia de uso único do token expirado*.
4. **Formato padronizado de erro da API** — ainda não documentado.

## 11. Checklist de boas práticas para a implementação

- Nunca logar token, chave privada ou dados biométricos, nem em modo debug.
- Sempre limpar completamente o secure storage (token + chaves) em logout ou ao detectar sessão revogada.
- PIN/Biometria é pré-condição obrigatória antes de qualquer leitura do token salvo — não pular essa checagem em nenhum fluxo, incluindo os de conveniência ("lembrar login").
- Testar explicitamente os cenários: token revogado remotamente, token expirado (>30 dias) tentando operação não permitida, token expirado tentando confirmação de aplicação (deve funcionar uma única vez), dispositivo sem conexão em cada um desses cenários.
