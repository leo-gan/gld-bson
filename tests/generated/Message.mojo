from std.collections import List

from runtime.datum import BsonDatum
from runtime.error import DecodeError
from wire.reader import WireReader
from wire.types import TY_BOOL, TY_DOCUMENT, TY_DOUBLE, TY_INT32, TY_INT64, TY_STRING
from wire.writer import WireWriter, digit_count

struct Message(Copyable, Movable, Defaultable, BsonDatum):
    var f_bool: Bool
    var f_int32: Int32
    var f_int64: Int64
    var f_float64: Float64
    var f_string: String
    var f_bool_2: Bool
    var f_int32_2: Int32
    var f_string_2: String

    def __init__(out self):
        self.f_bool = False
        self.f_int32 = 0
        self.f_int64 = 0
        self.f_float64 = 0.0
        self.f_string = ""
        self.f_bool_2 = False
        self.f_int32_2 = 0
        self.f_string_2 = ""

    def encoded_len(self) -> Int:
        var n = 5
        n += 8
        n += 1
        n += 9
        n += 4
        n += 9
        n += 8
        n += 11
        n += 8
        n += 10
        n += 5 + self.f_string.byte_length()
        n += 10
        n += 1
        n += 11
        n += 4
        n += 12
        n += 5 + self.f_string_2.byte_length()
        return n

    def encode_to(self, mut w: WireWriter):
        var at = w.begin_document()
        w.write_bool_field("f_bool", self.f_bool)
        w.write_i32_field("f_int32", self.f_int32)
        w.write_i64_field("f_int64", self.f_int64)
        w.write_f64_field("f_float64", self.f_float64)
        w.write_string_field("f_string", self.f_string)
        w.write_bool_field("f_bool_2", self.f_bool_2)
        w.write_i32_field("f_int32_2", self.f_int32_2)
        w.write_string_field("f_string_2", self.f_string_2)
        w.end_document(at)

    def decode_from[origin: ImmOrigin](mut self, mut r: WireReader[origin]) raises DecodeError:
        var end = r.enter_document()
        while r.pos < end - 1:
            var typ = r.read_u8()
            var key = r.read_cstring()
            if key == "f_bool":
                _ = typ
                self.f_bool = r.read_u8() != 0
            elif key == "f_int32":
                _ = typ
                self.f_int32 = r.read_i32()
            elif key == "f_int64":
                _ = typ
                self.f_int64 = r.read_i64()
            elif key == "f_float64":
                _ = typ
                self.f_float64 = r.read_f64()
            elif key == "f_string":
                _ = typ
                self.f_string = r.read_bson_string()
            elif key == "f_bool_2":
                _ = typ
                self.f_bool_2 = r.read_u8() != 0
            elif key == "f_int32_2":
                _ = typ
                self.f_int32_2 = r.read_i32()
            elif key == "f_string_2":
                _ = typ
                self.f_string_2 = r.read_bson_string()
            else:
                r.skip_value(typ)
        r.finish_document(end)
