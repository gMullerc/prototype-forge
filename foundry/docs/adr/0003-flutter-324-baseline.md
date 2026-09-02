# ADR 0003: Flutter 3.24 is the minimum compatibility baseline

Status: accepted

## Decision

All packages and applications compile on Flutter 3.24.0 and Dart 3.5.0. CI must keep a job on this minimum version even when development also runs on newer SDKs.

## Consequences

Newer language syntax and Flutter APIs cannot be introduced until the company baseline changes. The project uses `Color.withOpacity` rather than APIs added after Flutter 3.24.

