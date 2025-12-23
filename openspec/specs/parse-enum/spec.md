# ParseEnum Macro Specification

## Purpose

The `@ParseEnum` macro automatically generates binary parsing and printing code for Swift enums. It enables parsing of discriminated binary data formats by matching byte patterns to enum cases, optionally consuming matched bytes and parsing associated values.
## Requirements
### Requirement: Enum Declaration Macro

The `@ParseEnum` macro SHALL be an attached extension macro that generates `Parsable` and `Printable` protocol conformances for enums.

#### Scenario: Basic enum parsing
- **WHEN** an enum is annotated with `@ParseEnum`
- **AND** each case has a match macro (`@match`, `@matchAndTake`, or `@matchDefault`)
- **THEN** the macro generates an `init(parsing:)` initializer that matches byte patterns to cases
- **AND** generates a `printerIntel()` method that produces printing instructions

#### Scenario: Non-enum type error
- **WHEN** the `@ParseEnum` macro is applied to a non-enum type (struct, class, actor)
- **THEN** the macro emits a diagnostic error indicating only enums are supported

### Requirement: Accessor Control Parameters

The `@ParseEnum` macro SHALL accept two optional parameters to control access levels of generated extensions using `ExtensionAccessor` (see `specs/extension-accessor/spec.md`).

**Parameters:**
- `parsingAccessor: ExtensionAccessor` (default: `.follow`) - Controls access level for `Parsable` conformance
- `printingAccessor: ExtensionAccessor` (default: `.follow`) - Controls access level for `Printable` conformance

#### Scenario: Default accessor behavior
- **WHEN** a public enum uses `@ParseEnum` without accessor parameters
- **THEN** the generated `init(parsing:)` and `printerIntel()` SHALL have public access (following the enum's access level)

#### Scenario: Custom accessor override
- **WHEN** `@ParseEnum(parsingAccessor: .internal)` is applied to a public enum
- **THEN** the generated `init(parsing:)` SHALL have internal access (even though it's not valid in Swift)

### Requirement: Match Case Attribute Requirement

Every enum case MUST have exactly one match macro as its first attribute.

**Valid match macros:**
- `@match()` - Match raw value without consuming
- `@match(byte:)` - Match single byte without consuming
- `@match(bytes:)` - Match byte sequence without consuming
- `@match(length:)` - Match remaining buffer length without consuming
- `@matchAndTake()` - Match raw value and consume
- `@matchAndTake(byte:)` - Match single byte and consume
- `@matchAndTake(bytes:)` - Match byte sequence and consume
- `@matchDefault` - Default fallback case

#### Scenario: Missing match attribute error
- **WHEN** an enum case lacks any match macro
- **THEN** the macro emits a diagnostic error

#### Scenario: Parse attribute preceding match
- **WHEN** a case has `@parse()` before `@match()`
- **THEN** the macro emits a diagnostic error requiring match macro first

#### Scenario: Skip attribute preceding match
- **WHEN** a case has `@skip()` before `@match()`
- **THEN** the macro emits a diagnostic error requiring match macro first

### Requirement: Raw Value Matching with @match()

Cases annotated with `@match()` (no arguments) SHALL match bytes using the enum's `Matchable` protocol conformance.

**Constraints:**
- The enum or case MUST conform to `Matchable`
- Matched bytes are NOT consumed from the buffer

#### Scenario: Raw representable matching
- **GIVEN** an enum with `RawRepresentable` conformance:
  ```swift
  @ParseEnum
  enum Status: UInt8, Matchable {
      @match() case success = 0x00
      @match() case error = 0x01
  }
  ```
- **WHEN** parsing bytes `[0x00, ...]`
- **THEN** the result SHALL be `.success`
- **AND** the buffer position SHALL still start at position 0 (`0x00` not consumed)

### Requirement: Single Byte Matching with @match(byte:)

Cases annotated with `@match(byte:)` SHALL match a specific single byte value.

**Parameter:**
- `byte: UInt8` - The byte value to match (0x00-0xFF)

**Constraints:**
- Matched byte is NOT consumed from the buffer

#### Scenario: Single byte match without consumption
- **GIVEN** an enum with:
  ```swift
  @match(byte: 0x01) case first
  ```
- **WHEN** parsing bytes `[0x01, 0x02, 0x03]`
- **THEN** the result SHALL be `.first`
- **AND** the buffer SHALL still start at position 0 (`0x01` not consumed)

### Requirement: Byte Sequence Matching with @match(bytes:)

Cases annotated with `@match(bytes:)` SHALL match a sequence of bytes.

**Parameter:**
- `bytes: [UInt8]` - The byte sequence to match

**Constraints:**
- Matched bytes are NOT consumed from the buffer

#### Scenario: Multi-byte match without consumption
- **GIVEN** an enum with:
  ```swift
  @match(bytes: [0xFF, 0xD8]) case jpegHeader
  ```
- **WHEN** parsing bytes `[0xFF, 0xD8, 0xFF, 0xE0]`
- **THEN** the result SHALL be `.jpegHeader`
- **AND** the buffer SHALL still start at position 0 (`[0xFF, 0xD8]` not consumed)

### Requirement: Consuming Raw Value Match with @matchAndTake()

Cases annotated with `@matchAndTake()` (no arguments) SHALL match bytes using the `Matchable` protocol AND consume the matched bytes.

**Constraints:**
- The enum or case MUST conform to `Matchable`
- Matched bytes ARE consumed from the buffer

#### Scenario: Raw value match with consumption
- **GIVEN** an enum with:
  ```swift
  @ParseEnum
  enum Command: UInt8, Matchable {
    @matchAndTake() case command = 0x10
    @matchAndTake() case anotherCommand = 0x20
  }
  ```
- **WHEN** parsing bytes `[0x10, ...]`
- **THEN** the result SHALL be `.command`
- **AND** the buffer position SHALL advance by 1 byte after matching (`0x10` consumed)

### Requirement: Consuming Single Byte Match with @matchAndTake(byte:)

Cases annotated with `@matchAndTake(byte:)` SHALL match a single byte AND consume it.

**Parameter:**
- `byte: UInt8` - The byte value to match

#### Scenario: Single byte match with consumption
- **GIVEN** an enum with:
  ```swift
  @ParseEnum
  enum Action {
    @matchAndTake(byte: 0x01)
    @parse(endianness: .big)
    case setValue(UInt16)

    @matchAndTake(byte: 0x02)
    case getValue
  }
  ```
- **WHEN** parsing bytes `[0x01, 0x12, 0x34]`
- **THEN** the result SHALL be `.setValue(0x1234)`
- **AND** byte `0x01` SHALL be consumed before parsing the associated value

### Requirement: Consuming Byte Sequence Match with @matchAndTake(bytes:)

Cases annotated with `@matchAndTake(bytes:)` SHALL match a byte sequence AND consume it.

**Parameter:**
- `bytes: [UInt8]` - The byte sequence to match

#### Scenario: Multi-byte match with consumption
- **GIVEN** an enum with:
  ```swift
  @ParseEnum
  enum ImageFormat {
    @matchAndTake(bytes: [0x89, 0x50])
    case pngImage
  }
  ```
- **WHEN** parsing PNG file data starting with `[0x89, 0x50, ...]`
- **THEN** the result SHALL be `.pngImage`
- **AND** the 2-byte magic number (`[0x89, 0x50]`) SHALL be consumed from the buffer

### Requirement: Default Case with @matchDefault

Cases annotated with `@matchDefault` SHALL match when no other case matches.

**Constraints:**
- Only ONE `@matchDefault` case is allowed per enum
- The `@matchDefault` case MUST be the last case in the enum
- Buffer position does NOT advance

#### Scenario: Default case matching
- **GIVEN** an enum with:
  ```swift
  @ParseEnum
  enum Response {
    @match(byte: 0x00) case success
    @match(byte: 0x01) case failure
    @matchDefault case unknown
  }
  ```
- **WHEN** parsing bytes `[0xFF, ...]`
- **THEN** the result SHALL be `.unknown`
- **AND** the buffer position SHALL NOT advance (`0xFF` not consumed)

#### Scenario: Multiple default cases error
- **WHEN** an enum has more than one `@matchDefault` case
- **THEN** the macro emits a diagnostic error

#### Scenario: Non-trailing default case error
- **WHEN** a `@matchDefault` case is not the last case
- **THEN** the macro emits a diagnostic error

### Requirement: Associated Value Parsing with @parse()

Enum cases with associated values SHALL use `@parse` macros to define how each value is parsed.

**Supported parse macros:**
- `@parse()` - Default parsing using `Parsable`
- `@parse(endianness:)` - Endian-aware parsing using `EndianParsable`
- `@parse(byteCount:)` - Fixed-size parsing using `SizedParsable`
- `@parse(byteCount:endianness:)` - Combined control using `EndianSizedParsable`

#### Scenario: Associated value parsing
- **GIVEN** an enum case:
  ```swift
  @matchAndTake(byte: 0x01)
  @parse(endianness: .big)
  @parse(byteCount: 4)
  case data(UInt16, [UInt8])
  ```
- **WHEN** parsing bytes `[0x01, 0x00, 0x0A, 0xDE, 0xAD, 0xBE, 0xEF]`
- **THEN** the first associated value SHALL be `10` (UInt16, big-endian, `0x000A`)
- **AND** the second SHALL be `[0xDE, 0xAD, 0xBE, 0xEF]` (4 bytes)

#### Scenario: Mismatched parse attribute count error
- **WHEN** a case has more associated values than `@parse` macro or vice versa
- **THEN** the macro emits a diagnostic error about argument count mismatch

### Requirement: Skip Bytes in Associated Values with @skip()

The `@skip(byteCount:because:)` attribute SHALL cause the parser to skip a specified number of bytes when used on enum cases.

**Parameters:**
- `byteCount: Int` - Number of bytes to skip
- `because: String` - Documentation reason

#### Scenario: Skipping padding between values
- **GIVEN** an enum case:
  ```swift
  @matchAndTake(byte: 0x01)
  @skip(byteCount: 2, because: "alignment padding")
  @parse(endianness: .big)
  case aligned(Int16)
  ```
- **WHEN** parsing bytes `[0x01, 0xFF, 0xFF, 0x00, 0x10]`
- **THEN** byte `0x01` is matched and consumed
- **AND** bytes `[0xFF, 0xFF]` are skipped
- **AND** the associated value SHALL be `16` (from `[0x00, 0x10]`)

### Requirement: Case Matching Order

The generated parsing code SHALL attempt to match cases in the order they are declared in the enum.

#### Scenario: Order-dependent matching
- **GIVEN** an enum with:
  ```swift
  @match(bytes: [0x00, 0x01]) case specific
  @match(byte: 0x00) case general
  ```
- **WHEN** parsing bytes `[0x00, 0x01]`
- **THEN** the result SHALL be `.specific` (matched first due to declaration order)

### Requirement: No Match Error

When no case matches the input bytes AND no `@matchDefault` case exists, parsing SHALL throw an error.

#### Scenario: No matching case error
- **GIVEN** an enum without `@matchDefault`:
  ```swift
  @match(byte: 0x01) case first
  @match(byte: 0x02) case second
  ```
- **WHEN** parsing bytes `[0x03, ...]`
- **THEN** parsing SHALL throw `BinaryParserKitError.failedToParse`

### Requirement: Match Utility Function

The generated code SHALL use the `__match(_:in:)` utility function to check byte patterns.

#### Scenario: Empty bytes match
- **WHEN** `__match([], in: &span)` is called
- **THEN** it SHALL return `true` (empty pattern always matches)

#### Scenario: Byte pattern match
- **WHEN** `__match([0x01, 0x02], in: &span)` is called
- **AND** the span starts with `[0x01, 0x02, ...]`
- **THEN** it SHALL return `true`
- **AND** the span SHALL NOT be modified

### Requirement: Parsable Type Assertions for Associated Values

The generated code SHALL include compile-time type assertions for associated value types.

#### Scenario: Parsable type assertion
- **WHEN** an associated value uses `@parse()`
- **THEN** the generated code includes `__assertParsable(ValueType.self)`

#### Scenario: Endian parsable type assertion
- **WHEN** an associated value uses `@parse(endianness:)`
- **THEN** the generated code includes `__assertEndianParsable(ValueType.self)`

#### Scenario: Sized parsable type assertion
- **WHEN** an associated value uses `@parse(byteCount:)`
- **THEN** the generated code includes `__assertSizedParsable(ValueType.self)`

#### Scenario: Endian sized parsable type assertion
- **WHEN** an associated value uses `@parse(byteCount:endianness:)`
- **THEN** the generated code includes `__assertEndianSizedParsable(ValueType.self)`

### Requirement: Printable Conformance Generation

The macro SHALL generate a `Printable` protocol conformance that produces `PrinterIntel` for the enum.

#### Scenario: Enum printer intel generation
- **WHEN** `printerIntel()` is called on a parsed enum value
- **THEN** it returns `PrinterIntel.enum(EnumCasePrinterIntel)` for the matched case

#### Scenario: Match parse type in printer intel
- **WHEN** a case was matched with `@match()`
- **THEN** the `EnumCasePrinterIntel.parseType` SHALL be `.match`

#### Scenario: MatchAndTake parse type in printer intel
- **WHEN** a case was matched with `@matchAndTake()`
- **THEN** the `EnumCasePrinterIntel.parseType` SHALL be `.matchAndTake`

#### Scenario: MatchDefault parse type in printer intel
- **WHEN** a case was matched with `@matchDefault`
- **THEN** the `EnumCasePrinterIntel.parseType` SHALL be `.matchDefault`

#### Scenario: Associated value fields in printer intel
- **WHEN** a matched case has associated values
- **THEN** the `EnumCasePrinterIntel.fields` SHALL contain `FieldPrinterIntel` for each value
- **AND** each field SHALL include its `byteCount` and `endianness` if specified

### Requirement: Length-Based Matching with @match(length:)

Cases annotated with `@match(length:)` SHALL match when the remaining buffer size equals the specified length.

**Parameter:**
- `length: Int` - The exact number of remaining bytes to match

**Constraints:**
- Buffer position does NOT advance (non-consuming match)
- Can be combined with associated value parsing

#### Scenario: Length-based match without consumption
- **GIVEN** an enum with:
  ```swift
  @match(length: 4) case fourBytes
  @match(length: 8) case eightBytes
  ```
- **WHEN** parsing a buffer with exactly 4 remaining bytes
- **THEN** the result SHALL be `.fourBytes`
- **AND** the buffer SHALL still start at position 0

#### Scenario: Length match with associated values
- **GIVEN** an enum with:
  ```swift
  @match(length: 4)
  @parse(endianness: .big)
  case value(UInt32)
  ```
- **WHEN** parsing bytes `[0x12, 0x34, 0x56, 0x78]`
- **THEN** the result SHALL be `.value(0x12345678)`
- **AND** all 4 bytes SHALL be consumed by parsing the associated value

#### Scenario: No length match
- **GIVEN** an enum with:
  ```swift
  @match(length: 4) case fourBytes
  @match(length: 8) case eightBytes
  ```
- **WHEN** parsing a buffer with 6 remaining bytes
- **AND** no `@matchDefault` case exists
- **THEN** parsing SHALL throw `BinaryParserKitError.failedToParse`

### Requirement: Mutual Exclusivity of Matching Strategies

An enum using `@ParseEnum` SHALL use either byte-based matching OR length-based matching, but NOT both.

**Byte-based matching macros:**
- `@match()`, `@match(byte:)`, `@match(bytes:)`
- `@matchAndTake()`, `@matchAndTake(byte:)`, `@matchAndTake(bytes:)`

**Length-based matching macros:**
- `@match(length:)`

**Note:** `@matchDefault` is allowed with either strategy.

#### Scenario: Mixed matching strategies error
- **GIVEN** an enum with:
  ```swift
  @ParseEnum
  enum Invalid {
      @match(byte: 0x01) case byteCase
      @match(length: 4) case lengthCase
  }
  ```
- **WHEN** the macro is expanded
- **THEN** a diagnostic error SHALL be emitted indicating mixed matching strategies are not allowed

#### Scenario: Valid byte-based enum
- **GIVEN** an enum using only byte-based matching:
  ```swift
  @ParseEnum
  enum Valid {
      @match(byte: 0x01) case first
      @matchAndTake(bytes: [0x02, 0x03]) case second
      @matchDefault case other
  }
  ```
- **WHEN** the macro is expanded
- **THEN** no error SHALL be emitted

#### Scenario: Valid length-based enum
- **GIVEN** an enum using only length-based matching:
  ```swift
  @ParseEnum
  enum Valid {
      @match(length: 4) case short
      @match(length: 8) case long
      @matchDefault case other
  }
  ```
- **WHEN** the macro is expanded
- **THEN** no error SHALL be emitted

### Requirement: Match Length Utility Function

The generated code SHALL use the `__match(length:in:)` utility function to check remaining buffer length.

#### Scenario: Length match check
- **WHEN** `__match(length: 4, in: span)` is called
- **AND** the span has exactly 4 remaining bytes
- **THEN** it SHALL return `true`
- **AND** the span SHALL NOT be modified

#### Scenario: Length mismatch
- **WHEN** `__match(length: 4, in: span)` is called
- **AND** the span has 5 remaining bytes
- **THEN** it SHALL return `false`
