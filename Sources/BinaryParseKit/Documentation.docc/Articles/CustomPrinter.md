# Custom Printer

This articles describes how to implement a custom printer by conforming to the `Printer` protocol.

## Printer Protocol

The ``Printer`` protocols requires implementing a single method ``Printer/print(_:)-(PrinterIntel)`` that takes in a ``PrinterIntel`` and outputs ``Printer/PrinterOutput``.

``PrinterIntel`` provides context information about the parsed object and is in a recursive structure. There are the following cases:

- ``PrinterIntel/builtIn(_:)`` with ``PrinterIntel/BuiltInPrinterIntel``: for built-in types like `UInt8`, `Int32`, or user defined types that are not marked with `@ParseStruct` or `@ParseEnum`.
- ``PrinterIntel/skip(_:)`` with ``PrinterIntel/SkipPrinterIntel``: for skipped bytes.
- ``PrinterIntel/struct(_:)`` with ``PrinterIntel/StructPrinterIntel``: for types marked with `@ParseStruct`.
- ``PrinterIntel/enum(_:)`` with ``PrinterIntel/EnumPrinterIntel``: for types marked with `@ParseEnum`.
