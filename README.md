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
foundry/packages/prototype_interaction/      Pure Dart state, effects and form validation
foundry/packages/prototype_runtime/          Validation and engine
foundry/packages/prototype_flutter/          Flutter renderer and event bridge
foundry/packages/prototype_material_catalog/ Material fixture catalog (14 components)
foundry/packages/prototype_agent/            Provider-neutral application port
foundry/packages/prototype_export/           Provider-neutral export port
foundry/packages/prototype_gateway_protocol/ Versioned local wire contract
foundry/packages/prototype_gateway_client/   Transport-agnostic gateway adapter
foundry/packages/prototype_tool_discovery/   Extensible local CLI inventory
foundry/packages/prototype_material_exporter/ Deterministic Material draft exporter
foundry/packages/prototype_workspace/         Local projects, revisions and comments
foundry/services/local_gateway/              Local Dart service and OpenCode adapter
foundry/tool/                                Cross-platform SDK helpers
studio/                                      Flutter Web workbench
.opencode/skills/                            OpenCode skills for catalog maintenance
docs/                                       Product context, architecture, plans and ADRs
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

Before the first run on a new Windows machine, check the local prerequisites:

```powershell
.\doctor.ps1
```

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

The Studio offers a deterministic local agent, OpenCode and Copilot CLI. The
gateway starts `opencode serve` on demand and reuses the OpenCode authorization
already configured on the machine. The Copilot adapter runs `copilot -p` in a
restricted process and does not write to the repository. No login or credential
screen is part of the MVP.

Prototype Spec 1.1 adds an allowlisted local interaction runtime. Generated
fields can be edited, options can update state, conditional regions can appear
or disappear, and submit actions can validate CPF, CNPJ, minimum age and
required values. The canvas starts in `Interagir` mode and can switch to
`Inspecionar` when the PM wants actions recorded in the conversation. Existing
Prototype Spec 1.0 revisions remain readable and static.

The header also exposes a local tool inventory. It detects registered CLI tools
such as OpenCode, GitHub Copilot CLI, OpenAI Codex CLI, Claude Code, Gemini CLI
and Aider through the local gateway. Detection checks executable presence and
version only; it does not read or validate credentials.

The default model is `openai/gpt-5.6-luna`. It can be replaced without changing
the Studio:

```powershell
$env:PROTOTYPE_OPENCODE_MODEL = 'openai/gpt-5.6-luna'
.\run-local.ps1
```

The Windows launcher accepts `-GatewayHost` and `-GatewayPort` when another
loopback port is needed. Workspace backups can be exported and imported from
the `...` menu in the project bar.

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
