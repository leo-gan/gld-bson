# Techniques

This page explains how mojo-bson encodes and decodes, why those choices exist,
and which ideas were measured in other libraries and then dropped. It describes
the shipped code.

The library is written in Mojo. It does not call libbson, the Go mongo driver,
the Java `org.bson` package, or the Rust `bson` crate. The layouts below are
the BSON specification. The buffer and scan ideas are ports of what those
libraries do, written with Mojo `List`, `memcpy`, and little-endian stores.

The speed path is a generated struct: `encoded_len`, `encode_to`, and
`decode_from`. `BsonValue`, the dynamic tree, can hold any well-formed
document. It allocates more, and it is not the speed path.

## What the fast libraries actually do

The fast BSON encoders in the serializer benchmark are not DOM converters.

| Library | What the timed path does |
| --- | --- |
| libbson (C), and pymongo's C extension | Append into a buffer. Each nested document reserves 4 bytes and patches the length when it closes. An iterator walks the bytes in place. |
| mongo-go-driver | Append codecs write into a reusable `[]byte`. A codec cache avoids reflection on the hot path. |
| Java `org.bson` | Writes into a `ByteBuf`. Integers and doubles are raw little-endian stores. |
| Rust `bson` `RawDocument` | A decode view borrows the input. `to_vec` is the allocating path. |
| nlohmann `to_bson`, jsoncons `bson::encode` | Build a generic tree, then walk it. That extra tree is the cost. |

Two ideas show up in every fast encoder. The length of a document is patched,
because the count is a prefix and the writer does not want a second walk of
the bytes. Scalar values are stored, not formatted. Two ideas show up in every
slow encoder. A DOM is built before any byte is written, and names are turned
into heap strings before they are compared.

## Two paths

A generated struct implements `encoded_len`, `encode_to`, and `decode_from`.
Field names are byte literals in schema order on the encode path. The decoder
reads each name once, compares it with the schema names, and skips a name it
does not know. Missing fields keep their `__init__` value. Field order in the
input does not have to match the schema. BSON does not require an order.

`BsonValue` is an arena of nodes. A node stores child indexes, not a nested
`BsonValue`. A recursive `List` of the same struct is not a practical Mojo
value, because destruction and moves become cyclic. The arena keeps ownership
in one list.

## Encode

### Exact buffer, then one store

`WireWriter` sets the list **length** to the planned size. Each store writes
at a cursor. If the constructor only reserved capacity, every store would
resize from length 0. That was the failure mode measured for the JSON writer
in the sibling mojo-json library, and the same constructor is used here.

`encode` of a generated type calls `encoded_len` first. The number is the
document size: 4 bytes, plus each field, plus the final `0x00`. String sizes
are `4 + utf8_len + 1`. Nested documents add their own `encoded_len`. Array
indexes add the number of decimal digits in `0`, `1`, `2`, … . The writer
trims to the cursor in `finish` if the estimate was long. `ensure` grows only
when a caller under-counted.

### Length patch inside the exact buffer

A BSON document length includes bytes that have not been written yet. The
writer stores a zero int32, writes the fields, writes the final `0x00`, then
patches the int32. That is one pass over the payload. libbson does the same
close-frame for its builder API, because a builder does not know the size in
advance and so also grows the buffer geometrically.

Generated code knows the size, so the outer allocation does not grow. The
patch is still used, because the length is a prefix. Doing a second walk that
writes into a second buffer would copy every nested document.

JavaScript with scope (`0x0F`) is the exception that is easy to get wrong.
Its int32 covers a string and a nested document. The nested document already
ends in `0x00`. The outer frame patches the length and does **not** write a
second terminator. An extra `0x00` makes the document one byte longer than
pymongo.

### Names and scalars

A field name is a type byte, the raw UTF-8 name, and `0x00`. Generated encode
copies the name from a string literal. An array index is written as ASCII
digits into the buffer. It is not formatted with `String(i)` first.

int32, int64, and double are stored with a 4-byte or 8-byte little-endian
write. On linux-64 the host order is the BSON order, so the store is the
Mojo value's bits. A string is `int32` byte count (including the trailing
zero), the UTF-8 bytes, and `0x00`, copied with `memcpy`.

Decimal128 stays 16 bytes on this path. The IEEE 754-2008 BID layout used
here is the one pymongo writes: a sign bit, a 14-bit exponent biased by
6176 at bit 49 of the high word, and a coefficient that fits in 113 bits.
Extended JSON is the only caller that turns those bits into a decimal string.

## Decode

### Bounds

`enter_document` reads the int32 and checks three things. The count is at
least 5. The count is at most 16 MiB, which is the common engine limit. The
last byte inside that count is `0x00`, and the count does not run past the
input. The reader then parses elements until it is one byte before that end,
and requires the final byte to be zero.

An unknown type byte is an error. A known type with a truncated payload is
an error. Trailing bytes after the top-level document are an error for
`decode`.

### Names

`read_cstring` finds the zero with an 8-byte test, then a byte tail. The
test is the standard SWAR zero-byte check:
`(v - 0x0101010101010101) & ~v & 0x8080808080808080`. A long name does not
scan one byte at a time for the whole length.

Generated decode reads the name into a `String` once and compares it. That
allocates the name. `key_is` is the non-allocating compare for a single
literal: it matches bytes in place and still consumes the C string when the
match fails. The generated decoder does not use it, because a field list
needs one read and many comparisons. A hand-written benchmark client can
call `key_is` per expected name when the order is known.

`skip_value` advances by the type byte. Documents, arrays, and code-with-scope
jump by their int32. Strings jump by their int32. Scalars jump by a fixed
width. Unknown fields in a generated struct use this skip, so a later field
is still decoded.

### Extended JSON

Canonical Extended JSON writes an explicit key for each numeric type.
Relaxed Extended JSON writes int32 and int64 as JSON numbers, and a finite
datetime as `YYYY-MM-DDTHH:MM:SSZ` when the caller asks for relaxed text.
NaN, Infinity, and `-0.0` stay `{"$numberDouble":"..."}` in both modes,
because JSON numbers cannot say those values.

The text parser is a struct with its own byte list. A nested function that
captured the cursor did not compile on Mojo 1.0: the capture of the index
could not be inferred, and a span into the source string was invalidated by
the next call. Copying the input into a `List[Byte]` once makes the index
stable.

## Trade-offs

| Choice | Reason |
| --- | --- |
| Exact `encoded_len` plus a length patch | The allocation does not grow, and the prefix length is still filled in one payload walk. |
| Arena `BsonValue` | Any document, including deprecated types, without a recursive value type. |
| Generated structs for the speed path | The benchmark-shaped records do not need a tree. |
| Decimal128 kept as 16 bytes | BID parsing is only needed for Extended JSON. |
| linux-64 little-endian stores | BSON is defined as little-endian. The conda package is linux-64 only. |
| pymongo as an oracle | Byte identity is checked from outside the process. The Mojo binary does not link it. |

Ideas that were not shipped:

* Linking libbson. The result would be libbson's speed, not this library's.
* A DOM on the generated path. That is the nlohmann and jsoncons shape, and
  it pays for nodes the caller already has as fields.
* Geometric growth as the only strategy. It is right for an append-only
  builder that does not know the size. Generated code knows the size.
* Requiring schema order on decode. BSON documents from other drivers do not
  promise order. Skipping unknown names costs a type-sized advance and keeps
  the decoder usable.

The oracle in `tests_interop/oracle.py` checks byte identity for the scalar
types, nested documents, arrays, binary, ObjectId, datetime, regex,
JavaScript, JavaScript with scope, timestamp, min and max key, and
decimal128. That is the check that the length patch and the type layouts
match a production writer.
