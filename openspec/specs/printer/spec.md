# Printer Feature Specification

## Purpose

The Printer feature provides a mechanism to convert parsed binary data structures back into various output formats. It uses an intermediate representation (`PrinterIntel`) that decouples parsed types from output formatting, enabling multiple output formats (byte arrays, hex strings, Data) from the same parsed structure.

## Requirements

### Requirement: Printer Protocol Definition

The `Printer` protocol SHALL define the interface for converting `PrinterIntel` into output.

**Protocol Definition:**
```swift
public protocol Printer {
    associatedtype PrinterOutput
    func print(_ intel: PrinterIntel) throws -> PrinterOutput
}
```

#### Scenario: Custom printer implementation
- **WHEN** a type conforms to `Printer`
- **THEN** it MUST implement `print(_:)` that converts `PrinterIntel` to its `PrinterOutput` type

#### Scenario: Convenience overloads
- **WHEN** using the `Printer` protocol
- **THEN** extension methods SHALL provide overloads for printing `BuiltInPrinterIntel`, `StructPrintIntel`, `EnumCasePrinterIntel`, `SkipPrinterIntel`, and `Printable` types directly

### Requirement: Printable Protocol Definition

The `Printable` protocol SHALL enable types to produce printing instructions.

**Protocol Methods:**
- `func printerIntel() throws -> PrinterIntel` - Generates the intermediate representation
- `func printParsed<P: Printer>(printer: P) throws(PrinterError) -> P.PrinterOutput` - Prints using a specified printer

#### Scenario: Generating printer intel
- **WHEN** `printerIntel()` is called on a `Printable` type
- **THEN** it SHALL return a `PrinterIntel` value representing the type's binary structure

#### Scenario: Printing with custom printer
- **WHEN** `printParsed(printer:)` is called
- **THEN** it SHALL call `printerIntel()` and pass the result to the printer
- **AND** wrap any errors in `PrinterError`

### Requirement: PrinterIntel Intermediate Representation

The `PrinterIntel` enum SHALL represent all printable binary structures.

**Cases:**
- `.struct(StructPrintIntel)` - Struct with fields
- `.enum(EnumCasePrinterIntel)` - Enum case with optional associated values
- `.builtIn(BuiltInPrinterIntel)` - Primitive types
- `.skip(SkipPrinterIntel)` - Skipped bytes

#### Scenario: Struct intel structure
- **WHEN** a struct's `printerIntel()` is called
- **THEN** it SHALL return `.struct(StructPrintIntel(fields: [...]))`
- **AND** each field SHALL be represented as a `FieldPrinterIntel`

#### Scenario: Enum intel structure
- **WHEN** an enum's `printerIntel()` is called
- **THEN** it SHALL return `.enum(EnumCasePrinterIntel(...))` for the current case
- **AND** SHALL include the matched bytes, parse type, and associated value fields

### Requirement: StructPrintIntel Definition

`StructPrintIntel` SHALL contain printing information for struct types.

**Structure:**
```swift
public struct StructPrintIntel: Equatable {
    public let fields: [FieldPrinterIntel]
}
```

#### Scenario: Struct with multiple fields
- **WHEN** a struct has 3 parseable fields
- **THEN** `StructPrintIntel.fields` SHALL contain 3 `FieldPrinterIntel` elements in declaration order

### Requirement: FieldPrinterIntel Definition

`FieldPrinterIntel` SHALL contain printing information for individual fields.

**Structure:**
```swift
public struct FieldPrinterIntel: Equatable {
    public let byteCount: Int?
    public let endianness: Endianness?
    public let intel: PrinterIntel
}
```

#### Scenario: Field with known byte count
- **WHEN** a field was parsed with `@parse(byteCount: 4)`
- **THEN** `FieldPrinterIntel.byteCount` SHALL be `4`

#### Scenario: Field with known endianness
- **WHEN** a field was parsed with `@parse(endianness: .big)`
- **THEN** `FieldPrinterIntel.endianness` SHALL be `.big`

#### Scenario: Field without metadata
- **WHEN** a field was parsed with plain `@parse()`
- **THEN** `byteCount` and `endianness` SHALL be `nil`

### Requirement: EnumCasePrinterIntel Definition

`EnumCasePrinterIntel` SHALL contain printing information for enum cases.

**Structure:**
```swift
public struct EnumCasePrinterIntel: Equatable {
    public enum CaseParseType: Equatable {
        case match
        case matchAndTake
        case matchDefault
    }

    public let bytes: [UInt8]
    public let parseType: CaseParseType
    public let fields: [FieldPrinterIntel]
}
```

#### Scenario: Match case intel
- **WHEN** a case used `@match(byte: 0x01)`
- **THEN** `bytes` SHALL be `[0x01]`
- **AND** `parseType` SHALL be `.match`

#### Scenario: MatchAndTake case intel
- **WHEN** a case used `@matchAndTake(bytes: [0xFF, 0xD8])`
- **THEN** `bytes` SHALL be `[0xFF, 0xD8]`
- **AND** `parseType` SHALL be `.matchAndTake`

#### Scenario: MatchDefault case intel
- **WHEN** a case used `@matchDefault`
- **THEN** `bytes` SHALL be `[]`
- **AND** `parseType` SHALL be `.matchDefault`

### Requirement: BuiltInPrinterIntel Definition

`BuiltInPrinterIntel` SHALL contain printing information for primitive types.

**Structure:**
```swift
public struct BuiltInPrinterIntel: Equatable {
    public let bytes: [UInt8]
    public let fixedEndianness: Bool
}
```

#### Scenario: Integer type bytes
- **WHEN** a `UInt32` value of `256` is converted to `BuiltInPrinterIntel`
- **THEN** `bytes` SHALL be the big-endian representation `[0x00, 0x00, 0x01, 0x00]`

#### Scenario: Fixed endianness flag
- **WHEN** `fixedEndianness` is `true`
- **THEN** printers SHALL NOT flip byte order regardless of context endianness

### Requirement: SkipPrinterIntel Definition

`SkipPrinterIntel` SHALL contain information about skipped bytes.

**Structure:**
```swift
public struct SkipPrinterIntel: Equatable {
    public let byteCount: Int
}
```

#### Scenario: Skip representation
- **WHEN** `@skip(byteCount: 4, because: "padding")` was used
- **THEN** `SkipPrinterIntel.byteCount` SHALL be `4`

### Requirement: ByteArrayPrinter Implementation

The `ByteArrayPrinter` SHALL convert `PrinterIntel` to `[UInt8]`.

**Output Type:** `[UInt8]`

#### Scenario: Built-in type printing
- **WHEN** printing a `UInt16` value of `0x1234` with big-endian context
- **THEN** the output SHALL be `[0x12, 0x34]`

#### Scenario: Built-in type with little-endian
- **WHEN** printing a `UInt16` value with little-endian context
- **AND** `fixedEndianness` is `false`
- **THEN** bytes SHALL be reversed from big-endian storage

#### Scenario: Fixed endianness respected
- **WHEN** `fixedEndianness` is `true`
- **THEN** bytes SHALL NOT be reversed regardless of context endianness

#### Scenario: Byte count trimming big-endian
- **WHEN** `byteCount` is `2` and value bytes are `[0x00, 0x00, 0x12, 0x34]`
- **AND** context is big-endian
- **THEN** output SHALL be `[0x12, 0x34]` (last 2 bytes)

#### Scenario: Byte count trimming little-endian
- **WHEN** `byteCount` is `2` and value bytes are `[0x00, 0x00, 0x12, 0x34]`
- **AND** context is little-endian
- **THEN** output SHALL be `[0x34, 0x12]` (last 2 bytes, reversed)

#### Scenario: Struct printing
- **WHEN** printing a struct
- **THEN** output SHALL be the concatenation of all field outputs in order

#### Scenario: Enum matchAndTake printing
- **WHEN** printing an enum case with `parseType: .matchAndTake`
- **THEN** output SHALL include the discriminator bytes followed by associated value bytes

#### Scenario: Enum match printing
- **WHEN** printing an enum case with `parseType: .match`
- **THEN** output SHALL NOT include discriminator bytes (only associated values)

#### Scenario: Enum matchDefault printing
- **WHEN** printing an enum case with `parseType: .matchDefault`
- **THEN** output SHALL NOT include discriminator bytes

#### Scenario: Skip printing
- **WHEN** printing a `SkipPrinterIntel` with `byteCount: 3`
- **THEN** output SHALL be `[0x00, 0x00, 0x00]` (zero-filled)

### Requirement: HexStringPrinter Implementation

The `HexStringPrinter` SHALL convert `PrinterIntel` to a formatted hex string.

**Output Type:** `String`

#### Scenario: Default hex string format
- **WHEN** printing bytes `[0x01, 0x02, 0x0A, 0xFF]` with default formatter
- **THEN** output SHALL be `"01020AFF"`

#### Scenario: Custom separator
- **WHEN** using formatter with `separator: " "`
- **THEN** output SHALL be `"01 02 0A FF"`

#### Scenario: Custom prefix
- **WHEN** using formatter with `prefix: "0x"` and `separator: ", "`
- **THEN** output SHALL be `"0x01, 0x02, 0x0A, 0xFF"`

#### Scenario: Lowercase characters
- **WHEN** using formatter with `characterCase: .lower`
- **THEN** output SHALL use lowercase hex characters like `"01020aff"`

### Requirement: HexStringPrinterFormatter Protocol

The `HexStringPrinterFormatter` protocol SHALL define hex string formatting options.

**Default Implementation:** `DefaultHexStringPrinterFormatter`

**Initialization Parameters:**
- `separator: String` (default: `""`) - String between bytes
- `prefix: String` (default: `""`) - Prefix for each byte
- `characterCase: CharacterCase` (default: `.upper`) - `.upper` or `.lower`

#### Scenario: Custom formatter creation
- **WHEN** creating `DefaultHexStringPrinterFormatter(separator: "-", prefix: "\\x", characterCase: .lower)`
- **THEN** output format SHALL be like `"\\x01-\\x02-\\x0a"`

### Requirement: DataPrinter Implementation

The `DataPrinter` SHALL convert `PrinterIntel` to `Foundation.Data`.

**Output Type:** `Data`

#### Scenario: Data output conversion
- **WHEN** printing with `DataPrinter`
- **THEN** output SHALL be `Data` containing the same bytes as `ByteArrayPrinter` would produce

### Requirement: PrinterError Error Handling

The `PrinterError` enum SHALL represent errors that occur during printing.

**Cases:**
- `.intelConstructionFailed(underlying:)` - Error generating `PrinterIntel`
- `.notPrintable(type:)` - Type doesn't conform to `Printable`
- `.printingError(underlying:)` - Error during printer execution

#### Scenario: Intel construction failure
- **WHEN** `printerIntel()` throws an error
- **THEN** `printParsed(printer:)` SHALL throw `.intelConstructionFailed(underlying: originalError)`

#### Scenario: Printing failure
- **WHEN** the printer's `print(_:)` method throws
- **THEN** `printParsed(printer:)` SHALL throw `.printingError(underlying: originalError)`

### Requirement: Built-in Type Printable Conformances

All numeric types SHALL conform to `Printable`.

**Supported Integer Types:**
- `Int8`, `Int16`, `Int32`, `Int64`, `Int`
- `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt`
- `Int128`, `UInt128` (macOS 15.0+)

**Supported Floating Point Types:**
- `Float16`, `Float`, `Double`

#### Scenario: UInt32 printable conformance
- **WHEN** calling `printerIntel()` on a `UInt32` value
- **THEN** it SHALL return `.builtIn(BuiltInPrinterIntel(...))`
- **AND** bytes SHALL be in big-endian format

#### Scenario: Floating point printable conformance
- **WHEN** calling `printerIntel()` on a `Float` value
- **THEN** it SHALL return `.builtIn(BuiltInPrinterIntel(...))`
- **AND** bytes SHALL represent the IEEE 754 binary format

### Requirement: Round-Trip Consistency

Parsing and printing SHALL be consistent - printing a parsed value SHALL produce bytes that can be re-parsed to an equivalent value.

#### Scenario: Struct round-trip
- **GIVEN** original bytes for a struct
- **WHEN** parsing the bytes and then printing with `ByteArrayPrinter`
- **THEN** the output bytes SHALL be equivalent to the original input bytes

#### Scenario: Enum round-trip
- **GIVEN** original bytes for an enum with `@matchAndTake`
- **WHEN** parsing and printing
- **THEN** the output SHALL include discriminator bytes and associated value bytes
- **AND** re-parsing SHALL produce the same enum case

### Requirement: Utility Function for PrinterIntel Extraction

The `__getPrinterIntel<T>(_:)` utility function SHALL extract `PrinterIntel` from `Printable` values.

#### Scenario: Getting intel from printable
- **WHEN** calling `__getPrinterIntel(someValue)` where `someValue: Printable`
- **THEN** it SHALL return the result of `someValue.printerIntel()`

### Requirement: Nested Structure Printing

Printing SHALL handle nested structs and complex type hierarchies.

#### Scenario: Nested struct printing
- **GIVEN** a struct containing another `@ParseStruct` type as a field
- **WHEN** printing the outer struct
- **THEN** the inner struct's bytes SHALL be included in the output
- **AND** endianness context SHALL be properly propagated

#### Scenario: Struct with enum field printing
- **GIVEN** a struct containing a `@ParseEnum` field
- **WHEN** printing the struct
- **THEN** the enum's bytes (including discriminator if `@matchAndTake`) SHALL be included
