# ADR 0001: Own a small versioned prototype contract

Status: accepted

## Decision

Prototype Foundry defines `Prototype Spec 1.0`, a nested declarative JSON format. It is informed by declarative UI protocols but does not claim full A2UI compatibility.

## Rationale

The product needs a narrow set of approved components, Flutter 3.24 compatibility, deterministic validation and future code export. Implementing a small owned contract keeps those requirements explicit and prevents upstream API churn from crossing application boundaries.

## Consequences

The team owns migrations between contract versions and must maintain parser, validator and fixtures. In return, the runtime remains small, auditable and independent from AI providers and UI frameworks.

