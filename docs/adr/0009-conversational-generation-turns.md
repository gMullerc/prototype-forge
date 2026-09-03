# ADR 0009: Turnos conversacionais para composição

## Status

Accepted for the MVP.

## Context

Um briefing de produto raramente contém todas as decisões que mudam a
experiência. Gerar um contrato imediatamente força o agente a adivinhar e
transfere a descoberta de requisitos para uma revisão posterior. O Studio
precisa permitir uma conversa curta entre o PM e o agente, mantendo o contrato
como única entrada da renderização.

## Decision

Adicionar uma capacidade opcional `PrototypeConversationalAgent` ao pacote
`prototype_agent`. Cada resposta é um `PrototypeAgentTurn`, com exatamente uma
destas formas:

- `clarification`: uma pergunta curta e, opcionalmente, opções selecionáveis;
- `contract`: um documento Prototype Spec validável.

O gateway transmite a mesma sessão do provedor por meio de `conversationId`.
OpenCode e futuros adapters podem preservar contexto, enquanto o Studio
continua independente do protocolo do provedor. Agentes antigos que implementam
somente `PrototypeAgent.generate` permanecem compatíveis e geram um contrato
diretamente.

O agente pode fazer no máximo uma pergunta por rodada e deve perguntar somente
quando a resposta mudar materialmente a solução. Omissões pequenas são
resolvidas com padrões razoáveis. Uma pergunta não altera o protótipo aprovado
que já está no canvas; o PM pode responder digitando ou escolhendo uma opção.

## Consequences

- O PM participa da descoberta antes da composição final.
- O catálogo, o renderer e o runtime continuam recebendo somente contratos
  aprovados e validados.
- A UI precisa representar um estado `awaitingClarification` além de
  `generating`, `ready` e `error`.
- Cada provedor deve traduzir seu formato de resposta para a união neutra;
  nenhum detalhe de OpenCode pode vazar para o Studio.
- Conversas longas, geração incremental e edição direta do contrato continuam
  fora do escopo do MVP.

## Rejected alternatives

- **Sempre gerar imediatamente:** mais simples, mas aumenta adivinhações e
  contratos rejeitados.
- **Perguntas livres sem envelope:** dependem de parsing de texto frágil e não
  permitem distinguir com segurança pergunta de contrato.
- **Colocar o diálogo no renderer:** acopla descoberta de requisitos à camada
  visual e dificulta reaproveitar o runtime em outro host.
