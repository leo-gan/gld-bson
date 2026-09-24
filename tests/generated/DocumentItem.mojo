from std.collections import List

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct DocumentItem(Copyable, Movable, Defaultable, BsonDatum):
    var sku: String
    var qty: Int32
    var price_minor: Int64

    def __init__(out self):
        self.sku = ""
        self.qty = 0
        self.price_minor = 0

    def encoded_len(self) -> Int:
        var n = 5
        n += 5
        n += 5 + self.sku.byte_length()
        n += 5
        n += 4
        n += 13
        n += 8
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_string_field("sku", self.sku)
        w.write_i32_field("qty", self.qty)
        w.write_i64_field("price_minor", self.price_minor)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "sku":
                _ = typ
                self.sku = r.read_bson_string()
            elif key == "qty":
                _ = typ
                self.qty = r.read_i32()
            elif key == "price_minor":
                _ = typ
                self.price_minor = r.read_i64()
            else:
                r.skip_value(typ)
        r.finish_document(end)
