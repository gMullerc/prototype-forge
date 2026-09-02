# ADR 0004: Generated code is never executed by the preview

Status: accepted

## Decision

Agents produce only Prototype Spec JSON. The preview renders registered component factories. A future Dart exporter is deterministic and its output is a developer artifact, not an input executed by the Studio.

## Rationale

This preserves the design system, makes validation possible and keeps model output outside the executable trust boundary.

