# BSON for Mojo (`mojo-bson`)

| Field | Value |
| --- | --- |
| **Document title** | BSON serializer for the Mojo programming language |
| **Author** | Leonid Ganeline |
| **Date** | 2026-09-24 |
| **Status** | Shipped as 0.1.0 |
| **Target repo** | `/home/leo/PycharmProjects/GLD/gld-bson` |
| **License** | MIT, Copyright (c) 2026 Leonid Ganeline |
| **Mojo pin** | `mojo == 1.0.0` |
| **Spec** | [bsonspec.org](https://bsonspec.org/spec.html), MongoDB Extended JSON v2 |

## Summary

mojo-bson is a standalone Mojo library. The runtime and the code generator
do not link libbson or any other C, C++, or Rust BSON library. pymongo is a
test oracle only.

The public surface has three layers.

| Layer | Role |
| --- | --- |
| `wire` | Little-endian stores, C strings, document frames, skip |
| `runtime` | `BsonValue` arena, Decimal128, Extended JSON, `BsonDatum` |
| `schema` + `codegen` | JSON Schema (`bsonType`, `$ref`) to generated structs |

A generated struct is the speed path. `BsonValue` holds any document,
including deprecated types. Encode pre-sizes the buffer from `encoded_len`
and patches each document length in place. Decode accepts fields in any
order and skips unknown names.

The reasoning, the libraries that were read for ideas, and the choices that
were dropped are written up in [docs/techniques.md](docs/techniques.md).

## Decisions

| Decision | Reason |
| --- | --- |
| Full BSON type set, plus relaxed and canonical Extended JSON | The user locked the v1 surface to the specification, not a JSON subset. |
| JSON Schema as the code-generation input | BSON has no schema language. The sibling mojo-json library already uses JSON Schema. |
| Both a dynamic value and generated structs | Same product shape as mojo-json and mojo-cbor. |
| Version 0.1.0 is the first release | Do not burn a minor bump before anything is published. |
| `.env` is gitignored | `PREFIX_API_KEY` stays on the machine and in GitHub Actions secrets. |
| linux-64 only | Same pin and endian assumption as the other gld Mojo packages. |

## Package

`pixi.toml` and `conda.recipe/recipe.yaml` both say `0.1.0`. The conda
package name is `mojo-bson`. The CLI is `gld-bsongen-mojo`. Published
modules are `wire.mojoc`, `runtime.mojoc`, `schema.mojoc`, and `bson.mojoc`.
