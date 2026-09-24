from std.collections import List

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct Telemetry(Copyable, Movable, Defaultable, BsonDatum):
    var source: String
    var ts: Int64
    var tags: List[String]
    var values: List[Float64]

    def __init__(out self):
        self.source = ""
        self.ts = 0
        self.tags = List[String]()
        self.values = List[Float64]()

    def encoded_len(self) -> Int:
        var n = 5
        n += 8
        n += 5 + self.source.byte_length()
        n += 4
        n += 8
        n += 6
        var a_tags = 5
        var i_tags = 0
        while i_tags < len(self.tags):
            a_tags += 2 + digit_count(i_tags)
            a_tags += 5 + self.tags[i_tags].byte_length()
            i_tags += 1
        n += a_tags
        n += 8
        var a_values = 5
        var i_values = 0
        while i_values < len(self.values):
            a_values += 2 + digit_count(i_values)
            a_values += 8
            i_values += 1
        n += a_values
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_string_field("source", self.source)
        w.write_i64_field("ts", self.ts)
        var tags_at = w.begin_array_field("tags")
        var tags_i = 0
        while tags_i < len(self.tags):
            w.write_string_index(tags_i, self.tags[tags_i])
            tags_i += 1
        w.end_document(tags_at)
        var values_at = w.begin_array_field("values")
        var values_i = 0
        while values_i < len(self.values):
            w.write_f64_index(values_i, self.values[values_i])
            values_i += 1
        w.end_document(values_at)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "source":
                _ = typ
                self.source = r.read_bson_string()
            elif key == "ts":
                _ = typ
                self.ts = r.read_i64()
            elif key == "tags":
                var aend = r.enter_document()
                self.tags = List[String]()
                while r.pos < aend - 1:
                    var atyp = r.read_u8()
                    _ = r.read_cstring()
                    self.tags.append(r.read_bson_string())
                r.finish_document(aend)
            elif key == "values":
                var aend = r.enter_document()
                self.values = List[Float64]()
                while r.pos < aend - 1:
                    var atyp = r.read_u8()
                    _ = r.read_cstring()
                    self.values.append(r.read_f64())
                r.finish_document(aend)
            else:
                r.skip_value(typ)
        r.finish_document(end)
