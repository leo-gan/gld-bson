from std.testing import assert_equal, assert_true, TestSuite

from bson import decode, encode
from Document import Document
from DocumentItem import DocumentItem
from Message import Message
from Telemetry import Telemetry


def test_message_roundtrip() raises:
    var msg = Message()
    msg.f_bool = True
    msg.f_int32 = 150
    msg.f_int64 = Int64(-3)
    msg.f_float64 = 1.5
    msg.f_string = "hi"
    msg.f_bool_2 = False
    msg.f_int32_2 = -1
    msg.f_string_2 = "ok"
    var raw = encode(msg)
    var back = decode[Message](Span(raw))
    assert_true(back.f_bool)
    assert_equal(back.f_int32, Int32(150))
    assert_equal(back.f_int64, Int64(-3))
    assert_true(back.f_float64 == Float64(1.5))
    assert_true(back.f_string == "hi")
    assert_equal(back.f_int32_2, Int32(-1))
    assert_true(back.f_string_2 == "ok")


def test_nested_document() raises:
    var doc = Document()
    doc.id = "d1"
    doc.status = 2
    doc.meta.region = "us"
    doc.meta.version = 3
    var item = DocumentItem()
    item.sku = "a"
    item.qty = 4
    item.price_minor = 9
    doc.items.append(item^)
    var raw = encode(doc)
    var back = decode[Document](Span(raw))
    assert_true(back.id == "d1")
    assert_equal(back.status, Int32(2))
    assert_true(back.meta.region == "us")
    assert_equal(back.meta.version, Int32(3))
    assert_equal(len(back.items), 1)
    assert_true(back.items[0].sku == "a")
    assert_equal(back.items[0].qty, Int32(4))


def test_telemetry() raises:
    var t = Telemetry()
    t.source = "s"
    t.ts = 11
    t.tags.append("a")
    t.values.append(1.5)
    var raw = encode(t)
    var back = decode[Telemetry](Span(raw))
    assert_true(back.source == "s")
    assert_equal(back.ts, Int64(11))
    assert_equal(len(back.tags), 1)
    assert_equal(len(back.values), 1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
