# ADR 0007: Catalog-specific deterministic exporters

## Status

Accepted.

## Context

A Prototype Spec uses semantic component types, while readable production
Flutter code depends on concrete widgets, tokens and conventions from a design
system. Putting Material or company widget knowledge in the runtime would
couple preview validation to code generation.

## Decision

Define the neutral `PrototypeExporter` port in `prototype_export`. An exporter
receives an already validated `PrototypeDocument` and returns a source artifact
without writing files or repositories.

Implement Material support in the separate `prototype_material_exporter`
package. Each future design-system catalog owns a matching exporter adapter.
The Studio selects both implementations in its composition root.

## Consequences

- Export output is deterministic for a document and exporter version.
- The MVP presents source for explicit human review and clipboard copy only.
- No exporter can bypass runtime validation or create commits.
- A catalog and its exporter can evolve together without changing the neutral
  spec, runtime, agent or gateway packages.
