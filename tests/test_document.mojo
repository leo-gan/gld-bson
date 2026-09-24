from std.collections import List
from std.testing import assert_equal, assert_true, TestSuite

from bson import DecodeError, decode_document, encode_document
from runtime.value import BsonValue
from wire.types import BK_INT32, BK_STRING


def test_int_field() raises:
    var doc = BsonValue()
    var root = doc.new_document()
    doc.put_i32(root, "a", 1)
    var raw = encode_document(doc)
    # 4 length + type + "a\0" + int32 + nul = 12
    assert_equal(len(raw), 12)
    assert_equal(Int(raw[4]), 0x10)
    assert_equal(Int(raw[5]), ord("a"))
    var back = decode_document(Span(raw))
    assert_equal(back.nodes[back.root].kind, 3)
    var child = back.nodes[back.root].kids[0]
    assert_equal(back.nodes[child].kind, BK_INT32)
    assert_equal(back.nodes[child].i64, Int64(1))
    var again = encode_document(back)
    assert_equal(len(again), len(raw))
    var i = 0
    while i < len(raw):
        assert_equal(Int(again[i]), Int(raw[i]))
        i += 1


def test_string_field() raises:
    var doc = BsonValue()
    var root = doc.new_document()
    doc.put_string(root, "s", "hi")
    var raw = encode_document(doc)
    var back = decode_document(Span(raw))
    var child = back.nodes[back.root].kids[0]
    assert_equal(back.nodes[child].kind, BK_STRING)
    assert_true(back.nodes[child].s0 == "hi")


def test_empty() raises:
    var doc = BsonValue()
    _ = doc.new_document()
    var raw = encode_document(doc)
    assert_equal(len(raw), 5)
    assert_equal(Int(raw[4]), 0)


def test_truncated() raises:
    var raw = List[Byte]()
    raw.append(Byte(5))
    raw.append(Byte(0))
    raw.append(Byte(0))
    raw.append(Byte(0))
    var failed = False
    try:
        _ = decode_document(Span(raw))
    except _:
        failed = True
    assert_true(failed)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
