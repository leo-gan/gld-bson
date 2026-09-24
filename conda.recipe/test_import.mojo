from bson import DecodeError, decode_extjson


def main() raises:
    var _k = DecodeError.KIND_EOF
    var doc = decode_extjson("{\"a\":{\"$numberInt\":\"1\"}}")
    print("bson import ok", _k, len(doc.nodes))
