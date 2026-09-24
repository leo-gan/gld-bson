from std.collections import List
from DocumentMeta import DocumentMeta
from DocumentItem import DocumentItem

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct Document(Copyable, Movable, Defaultable, BsonDatum):
    var id: String
    var status: Int32
    var meta: DocumentMeta
    var items: List[DocumentItem]

    def __init__(out self):
        self.id = ""
        self.status = 0
        self.meta = DocumentMeta()
        self.items = List[DocumentItem]()

    def encoded_len(self) -> Int:
        var n = 5
        n += 4
        n += 5 + self.id.byte_length()
        n += 8
        n += 4
        n += 6
        n += self.meta.encoded_len()
        n += 7
        var a_items = 5
        var i_items = 0
        while i_items < len(self.items):
            a_items += 2 + digit_count(i_items)
            a_items += self.items[i_items].encoded_len()
            i_items += 1
        n += a_items
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_string_field("id", self.id)
        w.write_i32_field("status", self.status)
        w.write_type_key(TY_DOCUMENT, "meta")
        self.meta.encode_to(w)
        var items_at = w.begin_array_field("items")
        var items_i = 0
        while items_i < len(self.items):
            w.write_type_index(TY_DOCUMENT, items_i)
            self.items[items_i].encode_to(w)
            items_i += 1
        w.end_document(items_at)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "id":
                _ = typ
                self.id = r.read_bson_string()
            elif key == "status":
                _ = typ
                self.status = r.read_i32()
            elif key == "meta":
                _ = typ
                self.meta.decode_from(r)
            elif key == "items":
                var aend = r.enter_document()
                self.items = List[DocumentItem]()
                while r.pos < aend - 1:
                    var atyp = r.read_u8()
                    _ = r.read_cstring()
                    var item = DocumentItem()
                    item.decode_from(r)
                    self.items.append(item^)
                r.finish_document(aend)
            else:
                r.skip_value(typ)
        r.finish_document(end)
