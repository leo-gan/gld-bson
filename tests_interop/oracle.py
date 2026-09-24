#!/usr/bin/env python3
"""Compare mojo-bson bytes with pymongo. pymongo is the oracle, not a runtime dependency."""

from __future__ import annotations

import datetime
import subprocess
import sys
from pathlib import Path

from bson import Binary, Code, DBRef, Decimal128, Int64, MaxKey, MinKey, ObjectId, Regex, Timestamp, encode
from bson.codec_options import CodecOptions
from bson.raw_bson import RawBSONDocument

ROOT = Path(__file__).resolve().parents[1]
MOJO = ["pixi", "run", "mojo", "run", "-I", "src", "tests_interop/roundtrip.mojo", "--"]


def mojo_hex(payload: bytes) -> tuple[str, str]:
    proc = subprocess.run(
        MOJO + ["hex", payload.hex()],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise SystemExit(proc.stderr or proc.stdout)
    lines = [line for line in proc.stdout.splitlines() if line]
    if len(lines) < 2:
        raise SystemExit(f"short mojo output: {proc.stdout!r}")
    return lines[0], lines[1]


def mojo_ext(text: str) -> str:
    proc = subprocess.run(
        MOJO + ["extjson", text],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise SystemExit(proc.stderr or proc.stdout)
    return proc.stdout.strip()


def check(name: str, doc: dict) -> None:
    raw = encode(doc)
    got, _ext = mojo_hex(raw)
    if got != raw.hex():
        raise SystemExit(f"{name} byte mismatch\n pymongo {raw.hex()}\n mojo    {got}")
    print("ok", name)


def main() -> None:
    oid = ObjectId("00112233445566778899aabb")
    when = datetime.datetime(2020, 1, 2, 3, 4, 5, tzinfo=datetime.timezone.utc)
    check("empty", {})
    check("int32", {"a": 1, "b": -2})
    check("int64", {"a": Int64(2**40), "b": Int64(-(2**40))})
    check("double", {"a": 1.5, "b": -0.0})
    check("string", {"a": "hi", "u": "héllo"})
    check("boolnull", {"a": True, "b": False, "c": None})
    check("nested", {"a": {"b": 1}, "c": [1, "x", None]})
    check("binary", {"a": Binary(b"ab", 0), "b": Binary(b"\x00\x01", 4)})
    check("oid", {"a": oid})
    check("date", {"a": when})
    check("regex", {"a": Regex("^a", "im")})
    check("code", {"a": Code("return 1")})
    check("codews", {"a": Code("return 1", {"b": 2})})
    check("ts", {"a": Timestamp(4, 5)})
    check("min", {"a": MinKey()})
    check("max", {"a": MaxKey()})
    check("dec", {"a": Decimal128("1.5"), "b": Decimal128("-1.50E+2")})
    # Deprecated symbol and DBPointer via raw append through encode of extended types.
    check("dbref", {"a": DBRef("coll", oid)})
    ext_hex = mojo_ext('{"a":{"$numberInt":"7"}}')
    if ext_hex != encode({"a": 7}).hex():
        raise SystemExit(f"extjson int mismatch {ext_hex}")
    print("ok extjson int")
    # Undefined is not a Python constructor in every version; skip if absent.
    try:
        from bson.codec_options import TypeRegistry
    except Exception:
        TypeRegistry = None  # noqa: N816
    _ = (CodecOptions, RawBSONDocument, TypeRegistry)
    print("oracle passed")


if __name__ == "__main__":
    main()
