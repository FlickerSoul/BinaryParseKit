# ParseBitmask Macro Specification

## Purpose

The `@ParseBitmask` macro automatically generates binary bitmask parsing code for Swift structs and enums. It analyzes fields annotated with `@mask` directives and generates conformance to `BitmaskParsable` (for structs) or `Parsable` (for enums) protocols.

## ADDED Requirements

### Requirement: BitOrder Enum Definition

The `BitOrder` enum SHALL define bit ordering options within bytes.

**Cases:**
- `.msbFirst` - Most significant bit comes first (bit 7 of byte 0 is the first field)
- `.lsbFirst` - Least significant bit comes first (bit 0 of byte 0 is the first field)

#### Scenario: BitOrder availability
- **WHEN** a bitmask macro specifies bit ordering
- **THEN** both `.msbFirst` and `.lsbFirst` options SHALL be available

### Requirement: ExpressibleByBitmask Protocol

The `ExpressibleByBitmask` protocol SHALL define the interface for types that can be constructed from a bitmask integer.

**Definition:**
- `associatedtype RawValue: BinaryInteger & BitwiseCopyable`
- `init(bitmask: RawValue) throws(BitmaskParsableError)`

#### Scenario: Protocol conformance for bitmask structs
- **WHEN** a struct is annotated with `@ParseBitmask`
- **THEN** it SHALL conform to `ExpressibleByBitmask`
- **AND** the `init(bitmask:)` initializer SHALL extract bits into fields

### Requirement: BitmaskParsable Protocol

The `BitmaskParsable` protocol SHALL combine `Parsable`, `SizedParsable`, and `ExpressibleByBitmask` for types that parse binary bitmasks.

**Properties:**
- `static var bitCount: Int { get }`
- `static var endianness: Endianness? { get }` (default: `nil`)
- `static var bitOrder: BitOrder { get }` (default: `.msbFirst`)

#### Scenario: BitmaskParsable conformance
- **WHEN** a struct is annotated with `@ParseBitmask`
- **THEN** it SHALL conform to `BitmaskParsable`
- **AND** it SHALL be usable with `init(parsing:)` and `init(parsing:byteCount:)`

### Requirement: Struct Declaration Macro

The `@ParseBitmask` macro for structs SHALL be an attached extension macro that generates `BitmaskParsable` and `Printable` protocol conformance.

**Parameters:**
- `bitCount: Int?` (optional) - Total bits in bitmask; inferred from `@mask` fields if omitted
- `endianness: Endianness?` (optional) - Byte order for multi-byte bitmasks
- `bitOrder: BitOrder` (default: `.msbFirst`) - Bit ordering within bytes
- `parsingAccessor: ExtensionAccessor` (default: `.follow`) - Access level for parsing members
- `printingAccessor: ExtensionAccessor` (default: `.follow`) - Access level for printing members

#### Scenario: Basic struct bitmask parsing
- **WHEN** a struct is annotated with `@ParseBitmask`
- **AND** it contains fields with `@mask` attributes
- **THEN** the macro generates an `init(parsing:)` initializer that reads bytes and extracts bits
- **AND** generates an `init(bitmask:)` initializer for bit extraction

#### Scenario: Non-struct type error for struct macro
- **WHEN** the `@ParseBitmask` macro is applied to a class or actor
- **THEN** the macro emits a diagnostic error

#### Scenario: Endianness Validation

- **WHEN** the specified or infered `bitCount` is greated than 8, that is, more than one byte
- **AND** the `endianness` is missing
- **THEN** throw compile time error if possible, otherwise runtime error

### Requirement: Enum Declaration Macro

The `@ParseBitmask` macro for enums SHALL generate a hidden struct shim for parsing and an extension providing `Parsable` conformance.

**Parameters:**
- `bitCount: Int?` (optional) - Total bits in bitmask; inferred from raw value type if omitted
- `endianness: Endianness?` (optional) - Byte order for multi-byte bitmasks
- `bitOrder: BitOrder` (default: `.msbFirst`) - Bit ordering within bytes

**Constraints:**
- Enum MUST have a raw value type conforming to `BinaryInteger`
- Enum MUST NOT have associated values

#### Scenario: Basic enum bitmask parsing
- **GIVEN** an enum:
  ```swift
  @ParseBitmask(bitCount: 2)
  enum Direction: UInt8 {
      case north = 0b00
      case east  = 0b01
      case south = 0b10
      case west  = 0b11
  }
  ```
- **WHEN** parsing bytes `[0b10]`
- **THEN** the result SHALL be `.south`

#### Scenario: Enum struct shim generation
- **WHEN** `@ParseBitmask` is applied to an enum
- **THEN** a hidden struct `__Bitmask_EnumName` SHALL be generated
- **AND** the struct SHALL conform to `BitmaskParsable`
- **AND** the enum's `init(parsing:)` SHALL use the struct to parse bytes then map to cases

#### Scenario: Enum with associated values error
- **WHEN** `@ParseBitmask` is applied to an enum with associated values
- **THEN** the macro emits a diagnostic error

#### Scenario: Enum without raw values error
- **WHEN** `@ParseBitmask` is applied to an enum without raw values
- **THEN** the macro emits a diagnostic error

#### Scenario: Invalid enum raw value error
- **WHEN** parsing a bitmask that doesn't match any enum case
- **THEN** a `ThrownParsingError` SHALL be thrown

#### Scenario: Endianness Validation

- **WHEN** the specified or infered `bitCount` is greated than 8, that is, more than one byte
- **AND** the `endianness` is missing
- **THEN** throw compile time error if possible, otherwise runtime error

### Requirement: Mask Field Annotation

Fields in bitmask structs SHALL be annotated with `@mask` to specify their bit count.

**Variants:**
- `@mask(bitCount: Int)` - Explicit bit count
- `@mask()` - Infer bit count from field type's `bitWidth`

#### Scenario: Explicit bit count
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask(bitCount: 8)
  struct Flags {
      @mask(bitCount: 4) let high: UInt8
      @mask(bitCount: 4) let low: UInt8
  }
  ```
- **WHEN** parsing bytes `[0xAB]`
- **THEN** `high` SHALL be `0xA` (bits 7-4)
- **AND** `low` SHALL be `0xB` (bits 3-0) using MSB-first ordering

#### Scenario: Field without @mask error
- **WHEN** a stored property in a `@ParseBitmask` struct lacks `@mask` annotation
- **THEN** the macro emits a diagnostic error

### Requirement: Bit Count Validation

The macro SHALL validate that field bit counts are consistent.

#### Scenario: Bit count sum mismatch
- **WHEN** total `@mask` bit counts do not match the specified `bitCount`
- **THEN** the macro emits a diagnostic error with expected vs actual counts

#### Scenario: Bit count inference
- **WHEN** `bitCount` parameter is omitted
- **THEN** the total SHALL be inferred from sum of `@mask` field bit counts

#### Scenario: Non-byte-aligned bit count
- **WHEN** total bit count is not a multiple of 8
- **THEN** the bitmask SHALL be padded to the next byte boundary
- **AND** the generated code SHALL read the padded byte count

#### Scenario: `@match` annotated type requires `ExpressibleByBitmask` Protocol

- **WHEN** a field is marked by `@match`
- **THEN** the field's type must conform to `ExpressibleByBitmask`
- **AND** compile time check should be generated in the macro output with `__assertExpressibleByBitmask` utility function

### Requirement: Bit Ordering

The `bitOrder` parameter SHALL control how bits are extracted from bytes.

#### Scenario: MSB-first ordering (default)
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask(bitCount: 8, bitOrder: .msbFirst)
  struct Fields {
      @mask(bitCount: 2) let first: UInt8
      @mask(bitCount: 6) let second: UInt8
  }
  ```
- **WHEN** parsing bytes `[0b11_000001]` (binary: 11000001 = 0xC1)
- **THEN** `first` SHALL be `0b11` (3) - bits 7-6
- **AND** `second` SHALL be `0b000001` (1) - bits 5-0

#### Scenario: LSB-first ordering
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask(bitCount: 8, bitOrder: .lsbFirst)
  struct Fields {
      @mask(bitCount: 2) let first: UInt8
      @mask(bitCount: 6) let second: UInt8
  }
  ```
- **WHEN** parsing bytes `[0b000001_11]` (binary: 00000111 = 0x07)
- **THEN** `first` SHALL be `0b11` (3) - bits 1-0
- **AND** `second` SHALL be `0b000001` (1) - bits 7-2

### Requirement: Multi-Byte Bitmask with Endianness

Bitmasks larger than 8 bits SHALL support endianness control.

#### Scenario: 16-bit big-endian bitmask
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask(bitCount: 16, endianness: .big)
  struct Header {
      @mask(bitCount: 4) let version: UInt8
      @mask(bitCount: 12) let length: UInt16
  }
  ```
- **WHEN** parsing bytes `[0x41, 0x23]` (big-endian: 0x4123)
- **THEN** `version` SHALL be `0x4` (bits 15-12)
- **AND** `length` SHALL be `0x123` (bits 11-0) using MSB-first ordering

#### Scenario: 16-bit little-endian bitmask
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask(bitCount: 16, endianness: .little)
  struct Header {
      @mask(bitCount: 4) let version: UInt8
      @mask(bitCount: 12) let length: UInt16
  }
  ```
- **WHEN** parsing bytes `[0x23, 0x41]` (little-endian: 0x4123)
- **THEN** `version` SHALL be `0x4`
- **AND** `length` SHALL be `0x123`

### Requirement: Nested Bitmask Fields

The macro SHALL support struct bitmask fields that are other `BitmaskParsable` types for nested bit extraction.

#### Scenario: Nested bitmask struct
- **GIVEN** structs:
  ```swift
  @ParseBitmask(bitCount: 4)
  struct Inner {
      @mask(bitCount: 2) let high: UInt8
      @mask(bitCount: 2) let low: UInt8
  }

  @ParseBitmask(bitCount: 8)
  struct Outer {
      @mask(bitCount: 4) let first: Inner
      @mask(bitCount: 4) let second: UInt8
  }
  ```
- **WHEN** parsing bytes `[0xAB]`
- **THEN** `first.high` SHALL be `0b10` (2) - from bits 7-6 of 0xA
- **AND** `first.low` SHALL be `0b10` (2) - from bits 5-4 of 0xA
- **AND** `second` SHALL be `0xB`

### Requirement: Accessor Control Parameters

The `@ParseBitmask` macro SHALL accept accessor parameters per `ExtensionAccessor` spec.

**Parameters:**
- `parsingAccessor: ExtensionAccessor` (default: `.follow`)
- `printingAccessor: ExtensionAccessor` (default: `.follow`)

#### Scenario: Custom accessor override
- **WHEN** `@ParseBitmask(parsingAccessor: .internal)` is applied to a public struct
- **THEN** the generated parsing initializers SHALL have internal access

### Requirement: Computed Properties Exclusion

Computed properties in bitmask structs SHALL be ignored by the macro.

#### Scenario: Computed property ignored
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask(bitCount: 8)
  struct Flags {
      @mask(bitCount: 8) let raw: UInt8
      var isSet: Bool { raw != 0 }
  }
  ```
- **WHEN** the macro generates parsing code
- **THEN** only `raw` is included in bit extraction; `isSet` is not mentioned

### Requirement: Type Annotation Requirement

All `@mask` annotated fields MUST have explicit type annotations.

#### Scenario: Missing type annotation error
- **WHEN** a field like `@mask(bitCount: 4) let value` lacks a type annotation
- **THEN** the macro emits a diagnostic error requiring type annotation

### Requirement: Bit Extraction Utility

A utility function `__extractBits` SHALL be provided for bit extraction.

**Signature:**
```swift
func __extractBits<Source: BinaryInteger, Target: BinaryInteger>(
    from rawValue: Source,
    startBit: Int,
    bitCount: Int,
    totalBitCount: Int,
    bitOrder: BitOrder
) -> Target
```

#### Scenario: MSB-first extraction
- **WHEN** extracting bits with `.msbFirst` from `0b11001010` starting at bit 0 for 2 bits
- **THEN** the result SHALL be `0b11` (3) - the highest 2 bits

#### Scenario: LSB-first extraction
- **WHEN** extracting bits with `.lsbFirst` from `0b11001010` starting at bit 0 for 2 bits
- **THEN** the result SHALL be `0b10` (2) - the lowest 2 bits

### Requirement: Printable Conformance Generation

The macro SHALL generate a `Printable` protocol conformance for struct bitmasks.

#### Scenario: Bitmask printer intel generation
- **WHEN** `printerIntel()` is called on a parsed bitmask struct
- **THEN** it returns `PrinterIntel.struct(StructPrintIntel)` containing field information
- **AND** each field's `FieldPrinterIntel` SHALL include the bit count
