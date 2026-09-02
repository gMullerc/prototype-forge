# Architecture

## Objective

Prototype Foundry must let a product manager describe a screen, validate the result against an approved component catalog, render it safely, and eventually export readable Flutter code.

The language model is a composer. It never supplies executable Dart code to the preview runtime.

## Dependency direction

```text
studio application
  -> prototype_flutter
      -> prototype_runtime
          -> prototype_spec

prototype_material_catalog
  -> prototype_flutter
  -> prototype_runtime

studio
  -> prototype_agent
  -> prototype_gateway_client
      -> prototype_gateway_protocol

studio
  -> prototype_workspace
  -> prototype_export
      <- prototype_material_exporter

local_gateway
  -> prototype_gateway_protocol
  -> provider adapters
```

Dependencies point toward stable contracts. Provider adapters and design-system adapters stay at the edges.

## Packages

### prototype_spec

Pure Dart package responsible only for the versioned JSON format and structural decoding. It does not know Flutter, agents, catalogs or UI state.

### prototype_runtime

Pure Dart package that owns component contracts, property validation, limits, prototype snapshots and orchestration of decoding plus validation.

### prototype_flutter

Flutter adapter that recursively renders validated component nodes using factories supplied by a catalog. It emits typed action events and never interprets arbitrary code.

### prototype_material_catalog

Development fixture catalog built with Flutter Material. It currently covers the
layout primitives `Column`, `Row` and `List`; content and navigation elements
`Text`, `Icon`, `Divider`, `Button`, `Avatar`, `Badge`, `TextField`, `Notice`,
`Metric` and `ListItem`. The catalog also includes realistic local scenarios
for payment receipts, account login and a banking home screen.

`createMaterialPrototypeCatalog` accepts optional
`additionalFactories`. This keeps the fixture useful while allowing a product
catalog to add a temporary component during development without editing the
Material implementation. The company design system will eventually provide a
separate adapter that implements the same boundary.

### Design-system adapters

Every design system is an isolated adapter package. An adapter exposes the same
runtime contracts and Flutter factories, while translating the stable
Prototype Spec component types into the widgets and tokens of that design
system.

The Studio composition root selects exactly one catalog implementation. Adding
or replacing a catalog must require only a dependency plus a catalog factory
change in that composition root; `prototype_spec`, `prototype_runtime`,
`prototype_flutter`, the agent ports and the gateway do not change.

Adapters must not import one another, leak package-specific types into the
Prototype Spec, or require the model to know the underlying widget library. A
catalog conformance suite validates the same invariants for every adapter:
registered types, accepted properties, rendering, actions and rejection
diagnostics.

### studio

Flutter Web composition root and PM workbench. It owns provider selection, conversation presentation and prototype history through application-level ports.

### prototype_agent

Pure Dart provider-neutral port used by the Studio application. Deterministic,
OpenCode and future agents implement the same minimal interface.

### prototype_workspace

Pure Dart project and review domain. It owns immutable revisions, comments and
the persistence port without importing Flutter, browser APIs, agents, catalogs
or exporters. The Studio currently supplies a browser `localStorage` adapter;
another host can replace it without changing the domain package.

### prototype_export

Pure Dart export port that accepts an already validated `PrototypeDocument` and
returns a named source artifact. It does not know Flutter Material or any
company design system.

### prototype_material_exporter

Catalog-specific implementation of `prototype_export`. It converts registered
Material component types into readable Flutter source deterministically. A
company design-system integration must provide its own exporter adapter rather
than adding company widget knowledge to the neutral export port.

### prototype_gateway_protocol

Pure Dart versioned wire contract between a local client and the local gateway.
It contains no HTTP, Flutter or provider implementation.

### prototype_gateway_client

Transport-agnostic `PrototypeAgent` adapter. It converts the active runtime
catalog into protocol data and accepts an injected platform transport.

### local_gateway

Local Dart service and composition root for provider adapters. Its application
use case knows `PrototypeProvider`, while only the OpenCode infrastructure
adapter knows the OpenCode HTTP API or process lifecycle.

Generation requests have an explicit timeout boundary. The gateway defaults to
90 seconds per OpenCode generation and returns the stable `provider_timeout`
error code when that boundary is reached. The Studio can cancel its current
request at any time; a late response is ignored and cannot replace a newer
prototype state.

## Prototype request flow

```text
brief
  -> PrototypeAgent.generate
  -> local gateway protocol (for OpenCode)
  -> provider structured output
  -> raw Prototype Spec JSON
  -> PrototypeEngine.load
  -> PrototypeSpecDecoder
  -> PrototypeValidator
  -> PrototypeSnapshot.ready
  -> immutable local revision
  -> PrototypeSurface
  -> registered Material/design-system factories

approved revision
  -> catalog-specific PrototypeExporter
  -> reviewable Flutter draft
  -> explicit human copy/review
```

## Security boundaries

- Unknown component types are rejected.
- Unknown properties are rejected.
- IDs must be unique.
- Component count and tree depth are bounded.
- Actions are inert data emitted to the host application.
- Remote URLs, scripts, inline catalogs and arbitrary functions are not part of version 1.
- OpenCode tool permissions are denied for generation sessions.
- The gateway and OpenCode bind only to the loopback interface.
- Local project data stays in browser storage for the MVP.
- Export returns text for human review and never writes to a product repository.
