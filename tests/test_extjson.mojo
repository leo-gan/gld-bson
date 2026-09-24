from std.testing import assert_equal, assert_true, TestSuite

from bson import decode_document, decode_extjson, encode_document, encode_extjson
from runtime.decimal import decimal_parse, decimal_to_string
from runtime.text import format_datetime, parse_datetime


def test_canonical_int() raises:
    var doc = decode_extjson("{\"a\":{\"$numberInt\":\"1\"}}")
    var text = encode_extjson(doc, True)
    assert_true(text == "{\"a\":{\"$numberInt\":\"1\"}}")
    var raw = encode_document(doc)
    var back = decode_document(Span(raw))
    assert_equal(back.nodes[back.nodes[back.root].kids[0]].i64, Int64(1))


def test_decimal_one() raises:
    var d = decimal_parse("1")
    assert_true(decimal_to_string(d) == "1")
    var d2 = decimal_parse("1.5")
    assert_true(decimal_to_string(d2) == "1.5")
    var d3 = decimal_parse("-1.50E+2")
    assert_true(decimal_to_string(d3) == "-150")


def test_date_round() raises:
    var ms = parse_datetime("2020-01-02T03:04:05Z")
    assert_equal(ms, Int64(1577934245000))
    assert_true(format_datetime(ms) == "2020-01-02T03:04:05Z")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
