# Printer

The ``Printer`` protocol defines how to convert parsed data structures any format. The library provides three default printers: ``ByteArrayPrinter``, ``HexStringPrinter``, and ``DataPrinter``.

## Using Printers

Printer takes in a ``Printable`` object and produces a formatted representation. If you're using types marked by `@ParseStruct` or `@ParseEnum`, they automatically conform to ``Printable``. Note that calling ``Printable/printerIntel()-3gam7`` may throw an error if the underlying data types do not conform to ``Printable``.

### `ByteArrayPrinter`

The ``ByteArrayPrinter`` prints the parsed data as an array of bytes (`[UInt8]`). It has the following behavior:

- Bytes skipped by ``skip(byteCount:because:)`` are replaced by `0x00`. That is `@skip(byteCount: 2, because: "reserved")` will print as `[0x00, 0x00]`.

    For instance,

    ```swift
    @ParseStruct
    struct Example {
        @skip(byteCount: 2, because: "reserved")
        @parse(byteCount: 2, endianness: .little)
        let value: Int
    }

    // [0x00, 0x00, 0x02, 0x00]
    // where the first two 0x00 are from skip, and the last two bytes are from parsing the Int value 2 in big-endian
    try print(Example(value: 2).printParsed(printer: .byteArray))
    ```

- Bytes matched using non `matchAndTake` variants (that is, ``match()``, ``match(byte:)``, ``match(bytes:)``, and ``matchDefault()``) are not included in the output byte array.

    For instance,
    ```swift
    @ParseEnum
    enum ExampleEnum {
        @match(byte: 0x01)
        case first

        @matchAndTake(byte: 0x02)
        @parse(byteCount: 2, endianness: .big)
        case second(Int)
    }

    try print(ExampleEnum.first.printParsed(printer: .byteArray)) // []
    try print(ExampleEnum.second(0x01_02).printParsed(printer: .byteArray)) // [0x02, 0x01, 0x02]
    ```

### `HexStringPrinter`

The ``ByteArrayPrinter`` uses the ``ByteArrayPrinter`` to get the byte array and then converts it to a hexadecimal string representation. The ``ByteArrayPrinter`` takes a ``HexStringPrinterFormatter`` that formats a given byte array into a string. The default implementation ``DefaultHexStringPrinterFormatter`` converts each byte into a two letter string (with a prefix option) and joins them with a separator (default to empty string).

### `DataPrinter`

The ``DataPrinter`` prints the parsed data as a `Data` object. It converts the byte array obtained from ``ByteArrayPrinter`` into a `Data` object.
