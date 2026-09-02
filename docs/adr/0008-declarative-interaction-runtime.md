# ADR 0008 — Declarative interaction runtime

## Status

Accepted for the local MVP.

## Context

Prototype Spec 1.0 renders approved components and emits action events, but it
does not own mutable state. Text fields are read-only and button clicks can only
be observed by the Studio. PMs need to test simple form behavior without giving
generated content the ability to execute code.

## Decision

Prototype Spec 1.1 adds optional interaction metadata: initial scalar state,
named actions, node value bindings, conditional visibility, selected state and
validation rules. Existing 1.0 documents remain accepted and static.

State execution lives in the pure-Dart `prototype_interaction` package. The
engine supports only the registered effects `setValue`, `toggleValue`, `reset`,
`validate` and `showMessage`. It validates required fields, CPF, CNPJ and
minimum age. Flutter and design-system adapters read and update the engine only
through `PrototypeRenderContext`.

The Studio exposes two modes. `Interagir` applies declarative effects locally;
`Inspecionar` preserves action telemetry for design and engineering review.

## Consequences

- Generated Dart or JavaScript is still never executed.
- Design-system adapters remain replaceable and do not depend on the Studio.
- State is ephemeral and tied to the selected document.
- New effect types require an explicit contract, engine implementation, tests
  and security review.
- Multi-screen navigation and business API calls remain outside this decision.
