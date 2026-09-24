# Test data

The files under `testdata/` are inputs to tests. They are not a product
schema, and they are not fetched from another repository at runtime.

| Path | What it is | Why it is here |
| --- | --- | --- |
| `testdata/schema/benchmark_v2.json` | JSON Schema for `Message`, `Document`, `Telemetry`, `Strings`, and `Event` | These shapes are the records used by serializer comparisons. The generator turns them into `tests/generated/*.mojo`. |
| `tests/generated/` | Mojo structs emitted by `scripts/generate.sh` | Checked in so a test run does not need to regenerate first. `scripts/check-generated.sh` fails if they drift. |
| `tests_interop/oracle.py` | pymongo encoder | Builds documents and checks that this library re-encodes the same bytes. |

## Schema

`benchmark_v2.json` uses `$defs`. A field is a JSON Schema `type`
(`boolean`, `string`, `array`, `object`) or a BSON `bsonType`
(`int`, `long`, `double`). Nested structs are `$ref` values of the form
`#/$defs/Name`. An array's `items` is either a scalar or one `$ref`.

The names match the records in the sibling serializer benchmark: a flat
`Message`, a `Document` with `meta` and `items`, `Telemetry` with parallel
`tags` and `values` arrays, `Strings`, and `Event` with `attrs`. They are
ordinary test records.

## Oracle

`tests_interop/oracle.py` imports pymongo and calls `bson.encode`. For each
document it runs `tests_interop/roundtrip.mojo`, which decodes the bytes and
encodes them again. The hex strings must match.

The script also checks one canonical Extended JSON object,
`{"a":{"$numberInt":"7"}}`, against `encode({"a": 7})`.

pymongo is installed on the developer machine for that script. The Mojo
compiler does not see it. A unit test that only needs Mojo uses
`tests/test_document.mojo`, `tests/test_extjson.mojo`, and
`tests/test_generated.mojo`.

## Regenerating

```bash
pixi run generate
pixi run check-generated
python3 tests_interop/oracle.py
```

Do not hand-edit `tests/generated/*.mojo`. Change the schema or the emitter,
then run `scripts/generate.sh`.
