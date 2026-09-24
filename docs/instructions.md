# Instructions

These steps install the library, generate Mojo from a JSON Schema, and run
the tests. The runtime needs **Mojo 1.1.0**. Code generation is a Mojo
program in this repository. It does not shell out to another BSON library.

---

## Install

1. Install [pixi](https://pixi.sh/).
2. Clone the repository and install the Mojo 1.1.0 pin.

```bash
git clone https://github.com/leo-gan/gld-bson.git
cd gld-bson
pixi install
```

If `pixi install` returns 401 or 403 from `conda.modular.com`, put
`PREFIX_API_KEY` in a file named `.env` in this directory and run
`scripts/ci-setup.sh`. That file is listed in `.gitignore`. Do not commit it.

The published linux-64 package is on prefix.dev:

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-bson
```

The package installs `bson.mojoc`, `wire.mojoc`, `runtime.mojoc`,
`schema.mojoc`, and the `gld-bsongen-mojo` command.

## Generate

A schema file is JSON Schema plus MongoDB `bsonType` names (`int`, `long`,
`double`) and `$ref` entries under `$defs`. `scripts/generate.sh` reads
`testdata/schema/*.json` and writes `tests/generated/`.

```bash
pixi run generate
pixi run mojo run -I src src/codegen/cli.mojo -- --help
```

## Test

```bash
pixi run test
pixi run check-generated
python3 tests_interop/oracle.py
```

`pixi run test` runs every `tests/test_*.mojo` file. The oracle encodes
documents with pymongo and checks that this library decodes and re-encodes
the same bytes. pymongo is not linked into the Mojo binary.

## This site

```bash
pip install -r requirements-docs.txt
mkdocs build --strict
mkdocs serve
```

The published copy is [leo-gan.github.io/gld-bson](https://leo-gan.github.io/gld-bson/).
