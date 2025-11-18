# Custom Printer

This articles describes how to implement a custom printer by conforming to the `Printer` protocol.

## Printer Protocol

The ``Printer`` protocols requires implementing a single method ``Printer/print(_:)-(PrinterIntel)`` that takes in a ``PrinterIntel`` and outputs ``Printer/PrinterOutput``.
