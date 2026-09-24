from bson import decode, encode
from Message import Message


def main() raises:
    var msg = Message()
    msg.f_bool = True
    msg.f_int32 = 150
    msg.f_string = "hi"
    var raw = encode(msg)
    var back = decode[Message](Span(raw))
    print(back.f_int32, back.f_string)
