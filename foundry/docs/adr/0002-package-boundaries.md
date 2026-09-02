# ADR 0002: Separate specification, runtime and Flutter rendering

Status: accepted

## Decision

The JSON specification and runtime are pure Dart packages. Flutter rendering and component catalogs are adapters in separate packages.

## Rationale

This prevents Flutter widgets, design-system types and provider SDKs from leaking into the business contract. The same validated document can later be used by tests, a server, a CLI or a code exporter.

