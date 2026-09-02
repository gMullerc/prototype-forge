# ADR 0006: Local workspace behind a persistence port

## Status

Accepted.

## Context

The local MVP needs projects, immutable revisions and review comments to survive
a browser refresh. The domain must remain reusable if the Studio later moves to
a desktop host or a hosted service.

## Decision

Keep project, revision and comment models in the pure-Dart
`prototype_workspace` package. Persistence is represented by
`PrototypeProjectRepository`. The Flutter Web composition root supplies a
`localStorage` adapter; non-Web tests and hosts can supply another adapter.

A successful validated generation creates a new immutable revision. Comments
refer to a revision id and never mutate its stored contract.

## Consequences

- The workspace domain has no Flutter or browser dependency.
- Clearing browser site data removes MVP projects; there is no cloud backup.
- A hosted repository can be introduced without changing the domain model or
  Studio use cases.
- Rename, archive and deletion semantics require explicit future use cases.
