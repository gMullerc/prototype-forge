# Delivery plan

## Product thesis

Prototype Foundry is an internal product-design workbench, not a code generator
attached to one model. A PM describes an intent, an agent proposes a versioned
declarative document, the runtime validates it against an approved catalog, and
Flutter renders only registered components.

## Invariants

- The tool remains a repository independent from the former MVP and product apps.
- Core packages never import OpenCode, Copilot, a company design system or GenUI.
- Providers implement the `PrototypeAgent` port at the infrastructure edge.
- Design systems are catalog adapters; replacing one does not change the spec or runtime.
- Model output is data. The preview never executes generated Dart or JavaScript.
- Flutter 3.24 and Dart 3.5 remain the minimum CI lane until the company upgrades.

## Delivery sequence

### 1. Prove the contract and renderer — completed in the first slice

Deliver Prototype Spec 1.0, strict validation, a local Material catalog, a safe
Flutter renderer and a deterministic agent. Acceptance requires unit tests,
widget tests, a web build and one interactive PM journey.

### 1.1 Tornar a rejeição de contrato acionável — planejado

Uma falha de validação não deve terminar em uma mensagem técnica isolada. O
runtime e o Studio devem transformar cada issue em um diagnóstico que ajude o
PM a corrigir o briefing ou solicitar uma nova tentativa ao agente.

O diagnóstico deve preservar, de forma estruturada:

- código estável da regra violada;
- caminho do erro no contrato;
- id e tipo do componente afetado, quando identificáveis;
- propriedade inválida e valor recebido, sem expor dados sensíveis;
- expectativa da regra e uma sugestão de correção em linguagem clara.

Na interface, a rejeição deve:

- explicar o problema em português simples, sem depender de `$.screen.root.id`;
- apontar o componente, a propriedade ou a região da tela que falhou;
- separar causa, impacto e próximo passo recomendado;
- permitir consultar o contrato bruto e os detalhes técnicos quando necessário;
- suportar mais de um erro na mesma resposta, ordenado por prioridade;
- oferecer uma ação de reparo/regeneração somente quando houver contexto seguro
  para isso, mantendo a validação como autoridade final.

Exemplos de orientação esperada:

- `root` inválido: “A tela precisa começar pelo componente raiz `root`. Ajuste
  o componente inicial e tente gerar novamente.”
- componente desconhecido: “O componente `summary_card` não está disponível no
  catálogo atual. Escolha um componente registrado ou descreva a intenção sem
  indicar um tipo específico.”
- propriedade inválida: “No componente `saldo`, a propriedade `tone` recebeu
  `positive`. Use um token aceito pelo catálogo, como `success`.”

Exit criteria:

- cada regra pública de validação possui código, caminho e mensagem orientada à
  ação;
- o Studio identifica o componente afetado quando o contrato permite;
- testes cobrem raiz inválida, componente desconhecido, propriedade inválida,
  campo obrigatório ausente e múltiplos erros;
- o PM consegue distinguir erro do briefing, erro do agente e indisponibilidade
  do provedor;
- nenhuma sugestão de correção permite que conteúdo não validado alcance o
  renderer.

### 2. Connect OpenCode without coupling it to the core

Create a separate `prototype_opencode_adapter` package and a local gateway.
The adapter receives a catalog prompt, returns raw Prototype Spec JSON and owns
timeouts, cancellation, diagnostics and one repair attempt. The gateway invokes
the OpenCode installation and session already authorized on the PM machine. The
Studio only depends on `PrototypeAgent`; it does not ask for, store or manage an
API key.

Exit criteria:

- provider can be disabled without affecting local mode;
- malformed output cannot reach the renderer;
- no credential screen or credential storage is added to the MVP;
- provider contract tests run against recorded fixtures;
- errors identify provider, phase and remediation without exposing secrets.

### 3. Integrate the company design system

Build a catalog package in the company monorepo that maps Prototype Spec types
to approved widgets and tokens. Start with 10–15 high-value components and no
arbitrary colors, spacing or typography.

The integration must be plug-and-play: the company catalog, Material fixture
and any public test catalog implement the same adapter boundary. Switching the
catalog is a composition-root change, not a change to the contract, runtime,
renderer, agent or gateway.

Exit criteria:

- each component has a contract, model guidance, tests and a Flutter factory;
- golden tests cover representative states;
- the Material catalog can still run as a development fixture;
- a catalog can be replaced by changing only its adapter registration and
  dependency;
- a shared conformance suite passes for every catalog;
- no company package is imported by core packages.

### 4. Add the PM review workflow

Persist projects locally, keep immutable revisions, add device previews,
comments and side-by-side comparison. Export a deterministic Flutter draft only
after the team approves the quality bar; do not write to product repositories.

## Decision gates

1. After OpenCode: measure valid-first-response rate and repair rate.
2. After the company catalog: measure how much manual Flutter rewriting remains.
3. Before code export: agree on ownership and review of generated drafts.

## Main risks and controls

| Risk | Control |
| --- | --- |
| Model invents components or properties | Strict catalog validation and repair request |
| Prototype diverges from the design system | Token-only properties and catalog-owned factories |
| Provider lock-in | Stable `PrototypeAgent` port and adapter packages |
| Upstream Flutter/API drift | CI lane pinned to Flutter 3.24 |
| Generated code becomes a security boundary | Data-only preview and deterministic exporter |
| MVP architecture leaks into production | Independent repository, ADRs and package boundaries |

## Outside the local MVP

Authentication, accounts, hosted servers, cloud persistence and Electron are
not delivery milestones for this repository. They require a separate product
decision if the MVP proves valuable; no code or infrastructure is being prepared
for them now.
