# Why BSON

BSON is a binary format for documents. A document is an ordered list of
named fields. Each field has a type byte, a name that ends in a zero byte,
and a value. The whole document starts with a 32-bit byte count and ends
with a zero byte. The count includes itself and the final zero.

BSON was built so a store could walk a document without parsing text. The
type byte says how many bytes follow, or where the next length prefix is.
That is the property this library uses on both the generated path and the
dynamic path.

## Types

The type byte is from the [BSON specification](https://bsonspec.org/spec.html).

| Byte | Name | Value layout |
| --- | --- | --- |
| `0x01` | double | 8-byte IEEE 754 binary64, little-endian |
| `0x02` | string | int32 byte count, UTF-8, trailing `0x00` |
| `0x03` | document | nested document |
| `0x04` | array | document whose names are `"0"`, `"1"`, … |
| `0x05` | binary | int32 count, subtype byte, payload |
| `0x06` | undefined | no payload (deprecated) |
| `0x07` | ObjectId | 12 bytes |
| `0x08` | bool | `0x00` or `0x01` |
| `0x09` | datetime | int64 milliseconds since the Unix epoch |
| `0x0A` | null | no payload |
| `0x0B` | regex | two C strings: pattern, then options |
| `0x0C` | DBPointer | string, then 12-byte ObjectId (deprecated) |
| `0x0D` | JavaScript | string |
| `0x0E` | symbol | string (deprecated) |
| `0x0F` | JavaScript with scope | int32, string, document |
| `0x10` | int32 | 4-byte little-endian |
| `0x11` | timestamp | uint32 increment, then uint32 time |
| `0x12` | int64 | 8-byte little-endian |
| `0x13` | decimal128 | 16-byte IEEE 754 decimal128 |
| `0xFF` | Min key | no payload |
| `0x7F` | Max key | no payload |

Integers and floats are little-endian. This package is built for linux-64,
which is little-endian, so a store is a raw write of the Mojo value.

An array is not a packed list. It is a document. The name of element 12 is
the two characters `"12"` plus a zero byte, then the value.

## Extended JSON

Extended JSON is a text form of the same values. Canonical Extended JSON
writes every numeric type with an explicit key, such as
`{"$numberInt":"1"}`. Relaxed Extended JSON writes an int32 or int64 as a
JSON number and a UTC datetime as an ISO-8601 string when that is unambiguous.

The binary document is the interchange form. Extended JSON is for humans
and for tools that already speak JSON. The conversion is in `runtime/extjson.mojo`.
It is not the speed path.

## Two ways to use the library

A generated struct is a fixed set of fields from a JSON Schema. Encode writes
those fields in schema order. Decode accepts the fields in any order and
skips a name it does not know.

`BsonValue` is a tree that can hold any well-formed document, including
deprecated types. It allocates a node per value. Use it when the shape is
not known at compile time.
