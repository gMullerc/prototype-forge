# Roadmap

## Milestone 1 — Contract vertical slice — completed

- Prototype Spec 1.0
- strict decoder and validation issues
- actionable contract rejection feedback: rule, path, component and suggestion
- runtime snapshot lifecycle
- fourteen-component Material fixture catalog with realistic banking scenarios
- responsive Flutter Web workbench
- deterministic local agent
- Flutter 3.24 analysis, tests and Web build

## Milestone 2 — Agent adapters

- provider-neutral `PrototypeAgent` port
- OpenCode adapter and local gateway
- reuse the OpenCode session already authorized on the PM machine
- session lifecycle and UI cancellation with late-response protection
- malformed-response repair request
- local diagnostics for OpenCode invocation failures
- local inventory of installed agent CLIs without credential inspection

## Milestone 3 — Company design system

- catalog adapter package inside the company monorepo
- plug-and-play catalog boundary and shared adapter conformance tests
- property tokens instead of arbitrary visual values
- component documentation fragments for model prompts
- catalog contract tests and golden tests

## Milestone 4 — Product workflow — first local slice completed

- saved local projects and revisions
- side-by-side revisions
- device and breakpoint preview
- comments and decision notes
- deterministic Flutter code exporter
- versioned local workspace backup and restore
- Windows/macOS environment diagnostics

### Next refinements

- rename and archive local projects
- recoverable deletion for local data
- structural contract diff between revisions
- resolve and edit review notes
- company design-system exporter adapter
- export quality and rewrite-rate measurements
- configurable scenario registry for local fixture-based discovery

## Explicit non-goals for version 1

- executing generated Dart or JavaScript
- full A2UI compatibility
- arbitrary third-party widgets
- navigation graphs and production state management
- automatic commits to product repositories
- login, accounts or multi-user access
- hosted servers, cloud persistence or remote credentials
- Electron packaging
