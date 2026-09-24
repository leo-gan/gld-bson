from std.sys import argv

from runtime.error import DecodeError
from runtime.extjson import decode_extjson, encode_extjson
from runtime.text import hex_decode, hex_encode
from runtime.value import decode_document, encode_document


def main() raises:
    var args = argv()
    var mode = String()
    var payload = String()
    var i = 1
    while i < len(args):
        if args[i] == "hex" or args[i] == "extjson":
            mode = args[i]
            if i + 1 < len(args):
                payload = args[i + 1]
            break
        i += 1
    if mode.byte_length() == 0 or payload.byte_length() == 0:
        print("usage: roundtrip.mojo hex|extjson PAYLOAD")
        return
    if mode == "hex":
        var raw = hex_decode(payload)
        var doc = decode_document(Span(raw))
        var out = encode_document(doc)
        print(hex_encode(Span(out)))
        print(encode_extjson(doc, True))
        return
    if mode == "extjson":
        var doc = decode_extjson(payload)
        var out = encode_document(doc)
        print(hex_encode(Span(out)))
        return
    raise DecodeError(DecodeError.KIND_SYNTAX, 0, 0)
