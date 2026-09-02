# ADR 0005: Keep provider integration behind a local gateway

Status: accepted

## Decision

The Studio depends only on the `PrototypeAgent` port. Remote generation is an
adapter that speaks the versioned Prototype Gateway Protocol through an injected
transport. A separate local Dart service maps that stable protocol to provider
implementations such as OpenCode.

The OpenCode adapter uses the documented `opencode serve` HTTP API. No OpenCode
request or response type crosses the gateway boundary.

## Boundaries

```text
StudioSession
  -> PrototypeAgent
      -> GatewayPrototypeAgent
          -> GatewayTransport
              -> Prototype Gateway Protocol 1
                  -> GeneratePrototype use case
                      -> PrototypeProvider
                          -> OpenCodeApiClient
```

- `prototype_agent` owns the smallest provider-neutral application port.
- `prototype_gateway_protocol` owns wire DTOs and protocol versioning.
- `prototype_gateway_client` maps the runtime catalog to the wire protocol and
  is independent from HTTP, Flutter and OpenCode.
- platform HTTP code lives only in the Studio infrastructure layer.
- the local gateway owns provider selection, prompt construction and process
  lifecycle through injected interfaces.
- the OpenCode process reuses its already authorized local session.

## Safety

OpenCode receives a JSON Schema generated from the active component catalog as
part of the system instruction. Version 1.18.26 rejects the catalog's recursive
schema in its structured-output field, so the adapter requests text JSON and
parses it explicitly. The session denies tool permissions, known tools are
disabled, and the system prompt prohibits file or command access. The resulting
document is still passed through Prototype Foundry's independent decoder and
validator before rendering.

## Consequences

A provider, transport, catalog or UI can be replaced without changing the other
layers. The repository owns a small protocol and must evolve it explicitly when
requests or responses change.
