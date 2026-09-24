# Examples

These examples use the generated `Message` type. Generate it with
`pixi run generate` if `tests/generated/Message.mojo` is missing.
Run a file with `pixi run mojo run -I src -I tests/generated`.

---

## Encode and decode a struct

`examples/encode_message.mojo`:

```mojo
from bson import decode, encode
from Message import Message

def main() raises:
    var msg = Message()
    msg.f_bool = True
    msg.f_int32 = 150
    msg.f_string = "hi"
    var raw = encode(msg)
    var back = decode[Message](Span(raw))
    print(back.f_int32, back.f_string)
```

`encode` asks the struct for its byte count, allocates that many bytes, and
writes once. `decode` reads one document and rejects trailing bytes.

## A document without a schema

```mojo
from runtime.extjson import decode_extjson, encode_extjson
from runtime.value import encode_document

def main() raises:
    var doc = decode_extjson("{\"a\":{\"$numberInt\":\"1\"}}")
    var raw = encode_document(doc)
    print(encode_extjson(doc, True))
    print(len(raw))
```

`decode_extjson` accepts canonical or relaxed Extended JSON. `encode_extjson`
with `True` writes canonical Extended JSON. The bytes from `encode_document`
are the BSON document.

## Skip an unknown field

A generated decoder compares each name with the schema. A name that is not
a field is skipped by its type byte. The next field is still read. Missing
fields keep the value from `__init__`.
