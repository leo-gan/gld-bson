# mojo-bson

mojo-bson is a [BSON](https://bsonspec.org/spec.html) serializer written in
[Mojo](https://www.modular.com/mojo). The runtime and the code generator are
Mojo. They do not wrap libbson or any other C, C++, or Rust BSON library.

<div class="grid cards" markdown="1">

-   __Why BSON__

    ---

    What a BSON document is, how type bytes and length prefixes work, and how
    Extended JSON relates to the binary form.

    [:octicons-arrow-right-24: Read Why BSON](why-bson.md)

-   __Instructions__

    ---

    Install Mojo 1.0.0 with pixi, write a JSON Schema, generate Mojo, run the
    tests, and publish this site.

    [:octicons-arrow-right-24: Open Instructions](instructions.md)

-   __Examples__

    ---

    Encode and decode a generated struct, a dynamic document, and canonical
    Extended JSON.

    [:octicons-arrow-right-24: See Examples](examples.md)

-   __Techniques__

    ---

    How encode and decode work: exact buffers, length patching, cstring
    scans, and which ideas were kept or dropped.

    [:octicons-arrow-right-24: Read Techniques](techniques.md)

-   __Test data__

    ---

    What lives under `testdata/` (schemas and the pymongo oracle) and why
    each file is there.

    [:octicons-arrow-right-24: Read Test data](test-data.md)

</div>
