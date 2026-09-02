# Prototype Forge — documentação

Este diretório é a fonte central de contexto e decisões do Prototype Forge.
Ele deve concentrar o motivo do produto existir, os limites do MVP, a
arquitetura, os planos de evolução e as decisões que não devem ser perdidas
durante a implementação.

## O que estamos construindo

O Prototype Forge é uma ferramenta local para PMs descreverem uma hipótese de
produto em linguagem natural e visualizarem um protótipo interativo composto
somente por componentes aprovados em um catálogo de design system.

O fluxo é contract-first:

```text
brief do PM
  -> agente local (determinístico ou OpenCode)
  -> Prototype Spec JSON versionado
  -> decoder e validator
  -> snapshot aprovado ou diagnóstico acionável
  -> renderer Flutter
```

O modelo compõe dados. Ele não envia Dart, JavaScript ou funções para serem
executados no preview.

## Escopo atual do MVP

- execução local na máquina do PM;
- Flutter Web, com baseline Flutter 3.24 e Dart 3.5;
- OpenCode como primeiro provedor externo, usando a sessão já autorizada no
  computador;
- gateway local em loopback para isolar a integração com o provedor;
- catálogo Material público como fixture de desenvolvimento;
- renderer seguro baseado em componentes registrados;
- visualização do protótipo, sem commits automáticos em repositórios;
- sem login, contas, servidor hospedado, persistência em nuvem ou Electron.

Esses limites são intencionais. Uma futura hospedagem multiusuário será uma
decisão de produto posterior, não uma dependência escondida no MVP.

## Navegação

- [Contexto do produto](product-context.md) — problema, usuários, visão,
  princípios e escopo.
- [Arquitetura](architecture.md) — camadas, fluxo de dados, pacotes e limites
  de segurança.
- [Operação local](operations.md) — execução no Windows/macOS, configuração,
  portas e diagnóstico.
- [Plano de entrega](delivery-plan.md) — sequência de implementação, critérios
  de saída, riscos e decisões de produto.
- [Roadmap](roadmap.md) — marcos futuros e não-objetivos da versão 1.
- [ADRs](adr/) — decisões arquiteturais registradas.

## Decisões principais

| Tema | Decisão | Referência |
| --- | --- | --- |
| Contrato | Usar um Prototype Spec JSON próprio e versionado | [ADR 0001](adr/0001-own-versioned-contract.md) |
| Pacotes | Manter spec, runtime, renderer, catálogo, agente e gateway separados | [ADR 0002](adr/0002-package-boundaries.md) |
| Flutter | Manter Flutter 3.24 como baseline inicial | [ADR 0003](adr/0003-flutter-324-baseline.md) |
| Segurança | Nunca executar código gerado no preview | [ADR 0004](adr/0004-no-generated-code-execution.md) |
| OpenCode | Integrar por gateway local e adapter na borda | [ADR 0005](adr/0005-local-provider-gateway.md) |
| Projetos | Persistir revisões e comentários por uma porta local substituível | [ADR 0006](adr/0006-local-workspace-port.md) |
| Exportação | Manter exporters específicos de catálogo atrás de uma porta neutra | [ADR 0007](adr/0007-catalog-specific-exporters.md) |
| Design system | Catálogos plug-and-play, substituídos na composition root | [Arquitetura](architecture.md#design-system-adapters) |

## Organização do monorepo

```text
prototype-forge/
├── docs/                         # esta documentação
├── foundry/                      # código reutilizável e infraestrutura local
│   ├── packages/                 # contratos, runtime, renderer, adapters
│   ├── services/local_gateway/   # integração local com OpenCode
│   └── tool/                     # resolução do SDK Flutter
├── studio/                       # composition root Flutter Web
├── .opencode/skills/             # skill de manutenção de catálogos
├── run-local.ps1                 # inicialização no Windows
├── run-local.sh                  # inicialização no macOS/Linux
└── check.ps1                     # análise, testes e build Web
```

## Como manter esta documentação

- decisões que alteram limites ou dependências devem ganhar um novo ADR;
- mudanças de escopo e marcos devem atualizar o roadmap;
- mudanças na ordem de implementação ou nos critérios de aceite devem
  atualizar o plano de entrega;
- detalhes de execução local ficam em [Operação local](operations.md), não
  espalhados apenas em scripts;
- qualquer documentação que deixar de ser verdadeira deve ser corrigida no
  mesmo change que altera o comportamento.

O [README principal](../README.md) permanece como uma entrada rápida para
instalação e execução. Este diretório é a referência detalhada.
