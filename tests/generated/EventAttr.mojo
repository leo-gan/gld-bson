from std.collections import List

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct EventAttr(Copyable, Movable, Defaultable, BsonDatum):
    var key: String
    var value: String

    def __init__(out self):
        self.key = ""
        self.value = ""

    def encoded_len(self) -> Int:
        var n = 5
        n += 5
        n += 5 + self.key.byte_length()
        n += 7
        n += 5 + self.value.byte_length()
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_string_field("key", self.key)
        w.write_string_field("value", self.value)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "key":
                _ = typ
                self.key = r.read_bson_string()
            elif key == "value":
                _ = typ
                self.value = r.read_bson_string()
            else:
                r.skip_value(typ)
        r.finish_document(end)
