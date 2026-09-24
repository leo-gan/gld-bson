from std.collections import List

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct DocumentMeta(Copyable, Movable, Defaultable, BsonDatum):
    var region: String
    var version: Int32

    def __init__(out self):
        self.region = ""
        self.version = 0

    def encoded_len(self) -> Int:
        var n = 5
        n += 8
        n += 5 + self.region.byte_length()
        n += 9
        n += 4
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_string_field("region", self.region)
        w.write_i32_field("version", self.version)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "region":
                _ = typ
                self.region = r.read_bson_string()
            elif key == "version":
                _ = typ
                self.version = r.read_i32()
            else:
                r.skip_value(typ)
        r.finish_document(end)
