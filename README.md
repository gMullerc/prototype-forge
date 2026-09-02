# Prototype Forge

Contract-first prototype tooling for product teams.

Prototype Forge turns a product brief into a validated, declarative screen
specification. The same specification is rendered in Flutter and can later feed
a deterministic code exporter.

This monorepo is intentionally independent from the previous Prototype Studio
MVP and from Flutter GenUI. It contains no source copy, import, path dependency,
or runtime dependency on either implementation.

## Repository layout

```text
foundry/packages/prototype_spec/             Pure Dart JSON contract and decoder
foundry/packages/prototype_runtime/          Validation and engine
foundry/packages/prototype_flutter/          Flutter renderer and event bridge
foundry/packages/prototype_material_catalog/ Initial Material catalog
foundry/packages/prototype_agent/            Provider-neutral application port
foundry/packages/prototype_gateway_protocol/ Versioned local wire contract
foundry/packages/prototype_gateway_client/   Transport-agnostic gateway adapter
foundry/services/local_gateway/              Local Dart service and OpenCode adapter
foundry/tool/                                Cross-platform SDK helpers
studio/                                      Flutter Web workbench
.opencode/skills/                            OpenCode skills for catalog maintenance
foundry/docs/                                Architecture decisions and roadmap
```

## Compatibility baseline

- Flutter 3.24.x
- Dart 3.5.x
- No production dependency outside the Flutter/Dart SDK and local packages

## Run

```powershell
.\run-local.ps1
```

If Flutter is not on `PATH`, use
`.\run-local.ps1 -FlutterPath C:\path\to\flutter.bat`.

On macOS, use the shell script:

```bash
bash ./run-local.sh
```

If Flutter is not on `PATH`, pass the SDK executable as the first argument:

```bash
bash ./run-local.sh /Users/you/development/flutter/bin/flutter
```

The macOS script starts the local gateway on port `8790`, opens the Flutter Web
Studio in Chrome and shuts down only the gateway process started by that script.

Run the complete analysis, test and Web build gate with:

```powershell
.\check.ps1
```

The Studio offers both a deterministic local agent and OpenCode. The gateway
starts `opencode serve` on demand and reuses the OpenCode authorization already
configured on the machine. No login or credential screen is part of the MVP.

The default model is `openai/gpt-5.4-mini`. It can be replaced without changing
the Studio:

```powershell
$env:PROTOTYPE_OPENCODE_MODEL = 'openai/gpt-5.4'
.\run-local.ps1
```

See `foundry/services/local_gateway/README.md` for the local configuration boundaries.

## Catalog skill

When working on catalog maintenance through OpenCode, run it from the repository
root. The project-local `prototype-catalog-builder` skill is discovered from
`.opencode/skills` and can inspect a Flutter component to create or extend a
catalog adapter with contracts, factories, tokens, tests and documentation.

The Studio generation session keeps repository read/write tools disabled. Use
the skill in an explicit development session when catalog files need to change;
the PM chat remains limited to generating and previewing validated prototypes.

See [the delivery plan](docs/delivery-plan.md), [the architecture](docs/architecture.md)
and [the roadmap](docs/roadmap.md).
