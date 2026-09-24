from std.collections import List
from EventAttr import EventAttr

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct Event(Copyable, Movable, Defaultable, BsonDatum):
    var event_id: String
    var event_type: String
    var occurred_at: Int64
    var producer: String
    var attrs: List[EventAttr]

    def __init__(out self):
        self.event_id = ""
        self.event_type = ""
        self.occurred_at = 0
        self.producer = ""
        self.attrs = List[EventAttr]()

    def encoded_len(self) -> Int:
        var n = 5
        n += 10
        n += 5 + self.event_id.byte_length()
        n += 12
        n += 5 + self.event_type.byte_length()
        n += 13
        n += 8
        n += 10
        n += 5 + self.producer.byte_length()
        n += 7
        var a_attrs = 5
        var i_attrs = 0
        while i_attrs < len(self.attrs):
            a_attrs += 2 + digit_count(i_attrs)
            a_attrs += self.attrs[i_attrs].encoded_len()
            i_attrs += 1
        n += a_attrs
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_string_field("event_id", self.event_id)
        w.write_string_field("event_type", self.event_type)
        w.write_i64_field("occurred_at", self.occurred_at)
        w.write_string_field("producer", self.producer)
        var attrs_at = w.begin_array_field("attrs")
        var attrs_i = 0
        while attrs_i < len(self.attrs):
            w.write_type_index(TY_DOCUMENT, attrs_i)
            self.attrs[attrs_i].encode_to(w)
            attrs_i += 1
        w.end_document(attrs_at)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "event_id":
                _ = typ
                self.event_id = r.read_bson_string()
            elif key == "event_type":
                _ = typ
                self.event_type = r.read_bson_string()
            elif key == "occurred_at":
                _ = typ
                self.occurred_at = r.read_i64()
            elif key == "producer":
                _ = typ
                self.producer = r.read_bson_string()
            elif key == "attrs":
                var aend = r.enter_document()
                self.attrs = List[EventAttr]()
                while r.pos < aend - 1:
                    var atyp = r.read_u8()
                    _ = r.read_cstring()
                    var item = EventAttr()
                    item.decode_from(r)
                    self.attrs.append(item^)
                r.finish_document(aend)
            else:
                r.skip_value(typ)
        r.finish_document(end)
