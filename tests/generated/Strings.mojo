from std.collections import List

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct Strings(Copyable, Movable, Defaultable, BsonDatum):
    var items: List[String]

    def __init__(out self):
        self.items = List[String]()

    def encoded_len(self) -> Int:
        var n = 5
        n += 7
        var a_items = 5
        var i_items = 0
        while i_items < len(self.items):
            a_items += 2 + digit_count(i_items)
            a_items += 5 + self.items[i_items].byte_length()
            i_items += 1
        n += a_items
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        var items_at = w.begin_array_field("items")
        var items_i = 0
        while items_i < len(self.items):
            w.write_string_index(items_i, self.items[items_i])
            items_i += 1
        w.end_document(items_at)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "items":
                var aend = r.enter_document()
                self.items = List[String]()
                while r.pos < aend - 1:
                    var atyp = r.read_u8()
                    _ = r.read_cstring()
                    self.items.append(r.read_bson_string())
                r.finish_document(aend)
            else:
                r.skip_value(typ)
        r.finish_document(end)
