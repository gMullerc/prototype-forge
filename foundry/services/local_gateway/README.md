# Prototype Foundry local gateway

Local-only Dart service that maps Prototype Gateway Protocol 1 to registered
providers. It has no Flutter dependency and no provider type crosses its HTTP
boundary.

## Defaults

- Gateway: `http://127.0.0.1:8790`
- OpenCode: `http://127.0.0.1:4096`
- Model: `openai/gpt-5.6-luna`
- Provider: `opencode`

`run-local.ps1` starts and stops the gateway automatically. The gateway starts
OpenCode on demand only when no healthy server is already running.

## Optional local configuration

| Environment variable | Purpose |
| --- | --- |
| `PROTOTYPE_GATEWAY_PORT` | Change the gateway loopback port |
| `PROTOTYPE_OPENCODE_PORT` | Change the OpenCode loopback port |
| `PROTOTYPE_OPENCODE_EXECUTABLE` | Select another OpenCode executable |
| `PROTOTYPE_OPENCODE_MODEL` | Select `provider/model` |
| `PROTOTYPE_OPENCODE_VARIANT` | Select a model reasoning variant |
| `PROTOTYPE_OPENCODE_TIMEOUT_SECONDS` | Generation timeout, default `150` |
| `PROTOTYPE_WORKSPACE` | Change the isolated OpenCode working directory |

No credential variable belongs to Prototype Foundry. Authentication remains in
the independently installed OpenCode session.

The adapter asks OpenCode for JSON text and validates the returned document in
the Foundry decoder/runtime. This avoids depending on OpenCode's optional
`json_schema` response format while keeping unknown fields, components,
properties and interaction effects blocked before rendering.

If a generation exceeds the configured timeout, the gateway returns
`provider_timeout`. The Studio presents a retry-oriented message; canceling
from the Studio also prevents a late response from changing the visible
prototype.
