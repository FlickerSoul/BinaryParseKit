# ParseStruct Macro Specification

## Purpose

The `@ParseStruct` macro automatically generates binary parsing and printing code for Swift structs. It analyzes struct fields annotated with parsing directives and generates conformances to `Parsable` and `Printable` protocols.

## Requirements

### Requirement: Struct Declaration Macro

The `@ParseStruct` macro SHALL be an attached extension macro that generates `Parsable` and `Printable` protocol conformances for structs.

#### Scenario: Basic struct parsing
- **WHEN** a struct is annotated with `@ParseStruct`
- **AND** it contains fields with `@parse` attributes
- **THEN** the macro generates an `init(parsing:)` initializer that reads binary data into the struct fields
- **AND** generates a `printerIntel()` method that produces printing instructions

#### Scenario: Non-struct type error
- **WHEN** the `@ParseStruct` macro is applied to a non-struct type (class, enum, actor)
- **THEN** the macro emits a diagnostic error "The macro can only be used with struct declaration"

### Requirement: Accessor Control Parameters

The `@ParseStruct` macro SHALL accept two optional parameters to control access levels of generated extensions using `ExtensionAccessor` (see `specs/extension-accessor/spec.md`).

**Parameters:**
- `parsingAccessor: ExtensionAccessor` (default: `.follow`) - Controls access level for `Parsable` conformance
- `printingAccessor: ExtensionAccessor` (default: `.follow`) - Controls access level for `Printable` conformance

#### Scenario: Default accessor behavior
- **WHEN** a public struct uses `@ParseStruct` without accessor parameters
- **THEN** the generated `init(parsing:)` and `printerIntel()` SHALL have public access (following the struct)

#### Scenario: Custom accessor override
- **WHEN** `@ParseStruct(parsingAccessor: .internal, printingAccessor: .public)` is applied
- **THEN** the generated `init(parsing:)` SHALL have internal access
- **AND** the generated `printerIntel()` SHALL have public access

### Requirement: Basic Field Parsing with @parse()

Fields annotated with `@parse()` (no arguments) SHALL be parsed using the field type's default `Parsable` conformance.

#### Scenario: Simple parsable field
- **WHEN** a field is annotated with `@parse()`
- **AND** the field type conforms to `Parsable`
- **THEN** the generated code calls `FieldType.init(parsing: &span)`

#### Scenario: Type assertion for parsable
- **WHEN** a field uses `@parse()`
- **THEN** the generated code includes `__assertParsable(FieldType.self)` for compile-time validation

### Requirement: Endianness-Aware Parsing with @parse(endianness:)

Fields annotated with `@parse(endianness:)` SHALL be parsed with explicit byte order control.

**Parameter:**
- `endianness: Endianness` - Either `.big` or `.little`

#### Scenario: Big-endian parsing
- **WHEN** a `UInt32` field is annotated with `@parse(endianness: .big)`
- **AND** the input bytes are `[0x00, 0x00, 0x00, 0x01]`
- **THEN** the parsed value SHALL be `1`

#### Scenario: Little-endian parsing
- **WHEN** a `UInt32` field is annotated with `@parse(endianness: .little)`
- **AND** the input bytes are `[0x01, 0x00, 0x00, 0x00]`
- **THEN** the parsed value SHALL be `1`

#### Scenario: Type assertion for endian parsable
- **WHEN** a field uses `@parse(endianness:)`
- **THEN** the generated code includes `__assertEndianParsable(FieldType.self)` for compile-time validation

### Requirement: Fixed-Size Parsing with @parse(byteCount:)

Fields annotated with `@parse(byteCount:)` SHALL read a specific number of bytes regardless of the type's natural size.

**Parameter:**
- `byteCount: Int` - The exact number of bytes to read

#### Scenario: Reading fewer bytes than type size
- **WHEN** a `UInt32` field is annotated with `@parse(byteCount: 2)`
- **AND** the input bytes are `[0x01, 0x02]`
- **THEN** the value SHALL be parsed from only 2 bytes

#### Scenario: Type assertion for sized parsable
- **WHEN** a field uses `@parse(byteCount:)`
- **THEN** the generated code includes `__assertSizedParsable(FieldType.self)` for compile-time validation

### Requirement: Combined Byte Count and Endianness with @parse(byteCount:endianness:)

Fields annotated with `@parse(byteCount:endianness:)` SHALL be parsed with both fixed byte count and explicit byte order control.

**Parameters:**
- `byteCount: Int` - The exact number of bytes to read
- `endianness: Endianness` - Either `.big` or `.little`

#### Scenario: Fixed size with big-endian
- **WHEN** a `UInt64` field is annotated with `@parse(byteCount: 4, endianness: .big)`
- **AND** the input bytes are `[0x00, 0x00, 0x00, 0xFF]`
- **THEN** the parsed value SHALL be `255`

#### Scenario: Type assertion for endian sized parsable
- **WHEN** a field uses `@parse(byteCount:endianness:)`
- **THEN** the generated code includes `__assertEndianSizedParsable(FieldType.self)` for compile-time validation

### Requirement: Variable-Length Parsing with @parse(byteCountOf:)

Fields annotated with `@parse(byteCountOf:)` SHALL use another field's value to determine byte count.

**Parameter:**
- `byteCountOf: KeyPath` - A key path to a previously parsed field containing the byte count

#### Scenario: Length-prefixed data parsing
- **GIVEN** a struct with fields:
  ```swift
  @parse() let length: UInt8
  @parse(byteCountOf: \.length) let data: [UInt8]
  ```
- **WHEN** the input bytes are `[0x03, 0xAA, 0xBB, 0xCC]`
- **THEN** `length` SHALL be `3`
- **AND** `data` SHALL be `[0xAA, 0xBB, 0xCC]`

#### Scenario: Field ordering constraint
- **WHEN** `@parse(byteCountOf:)` references a field
- **THEN** the referenced field MUST be declared before the current field in the struct

### Requirement: Variable-Length with Endianness via @parse(byteCountOf:endianness:)

Fields annotated with `@parse(byteCountOf:endianness:)` SHALL be parsed using another field's value for byte count with explicit byte order control.

**Parameters:**
- `byteCountOf: KeyPath` - Key path to field containing byte count
- `endianness: Endianness` - Either `.big` or `.little`

#### Scenario: Variable length big-endian parsing
- **GIVEN** a struct with:
  ```swift
  @parse() let size: UInt8
  @parse(byteCountOf: \.size, endianness: .big) let value: UInt32
  ```
- **WHEN** `size` is `2` and subsequent bytes are `[0x00, 0x01]`
- **THEN** `value` SHALL be `1` (parsed as 2 bytes, big-endian)

### Requirement: Remaining Bytes Parsing with @parseRest()

Fields annotated with `@parseRest()` SHALL consume all remaining bytes from the parsing buffer.

**Constraints:**
- Only ONE `@parseRest` field is allowed per struct
- The `@parseRest` field MUST be the last parseable field in the struct

#### Scenario: Consuming remaining bytes
- **GIVEN** a struct with:
  ```swift
  @parse(byteCount: 2) let header: UInt16
  @parseRest let payload: Data
  ```
- **WHEN** the input has 10 bytes total
- **THEN** `header` consumes 2 bytes
- **AND** `payload` consumes the remaining 8 bytes

#### Scenario: Multiple @parseRest error
- **WHEN** a struct has more than one `@parseRest` field
- **THEN** the macro emits a diagnostic error

#### Scenario: Non-trailing @parseRest error
- **WHEN** a `@parseRest` field is not the last field
- **THEN** the macro emits a diagnostic error

### Requirement: Remaining Bytes with Endianness via @parseRest(endianness:)

Fields annotated with `@parseRest(endianness:)` SHALL consume remaining bytes with endianness control.

**Parameter:**
- `endianness: Endianness` - Either `.big` or `.little`

#### Scenario: Remaining bytes with little-endian
- **WHEN** a field is annotated with `@parseRest(endianness: .little)`
- **THEN** all remaining bytes are parsed with little-endian byte order

### Requirement: Skip Bytes with @skip(byteCount:because:)

The `@skip(byteCount:because:)` attribute SHALL cause the parser to skip a specified number of bytes before parsing the field.

**Parameters:**
- `byteCount: Int` - Number of bytes to skip
- `because: String` - Documentation reason for the skip

#### Scenario: Skipping padding bytes
- **GIVEN** a struct with:
  ```swift
  @skip(byteCount: 2, because: "reserved bytes")
  @parse()
  let value: UInt32
  ```
- **WHEN** parsing begins
- **THEN** 2 bytes are skipped before parsing `value`

#### Scenario: Multiple attributes on single field
- **WHEN** a field has both `@skip` and `@parse` attributes
- **THEN** the skip operation executes first, then the parse operation

### Requirement: Computed Properties Exclusion

Computed properties (fields with accessors) SHALL be ignored by the macro and not included in parsing.

#### Scenario: Computed property ignored
- **GIVEN** a struct with:
  ```swift
  @parse() let raw: UInt8
  var computed: Int { Int(raw) * 2 }
  ```
- **WHEN** the macro generates parsing code
- **THEN** only `raw` is parsed; `computed` is not mentioned in generated code

### Requirement: Type Annotation Requirement

All parseable fields MUST have explicit type annotations.

#### Scenario: Missing type annotation error
- **WHEN** a field like `@parse() let value` lacks a type annotation
- **THEN** the macro emits a diagnostic error requiring type annotation

### Requirement: Parse Attribute Requirement

All non-computed stored properties MUST have a parsing attribute (`@parse`, `@parseRest`, or `@skip` with subsequent `@parse`).

#### Scenario: Missing parse attribute error
- **WHEN** a stored property lacks any parsing attribute
- **THEN** the macro emits a diagnostic error

### Requirement: Identifier Definition Requirement

Fields MUST use simple identifier patterns, not destructuring patterns.

#### Scenario: Destructuring pattern error
- **WHEN** a field uses destructuring like `let (a, b): (Int, Int)`
- **THEN** the macro emits a diagnostic error

### Requirement: Conflicting Byte Count Error

Fields MUST NOT specify both `byteCount` and `byteCountOf` parameters.

#### Scenario: Conflicting parameters error
- **WHEN** a field is annotated with `@parse(byteCount: 4, byteCountOf: \.size)`
- **THEN** the macro emits a diagnostic error about conflicting byte count specifications

### Requirement: Printable Conformance Generation

The macro SHALL generate a `Printable` protocol conformance that produces `PrinterIntel` for the struct.

#### Scenario: Struct printer intel generation
- **WHEN** `printerIntel()` is called on a parsed struct
- **THEN** it returns `PrinterIntel.struct(StructPrintIntel)` containing field information

#### Scenario: Field metadata in printer intel
- **WHEN** a field was parsed with `@parse(byteCount: 4, endianness: .big)`
- **THEN** the corresponding `FieldPrinterIntel` SHALL include `byteCount: 4` and `endianness: .big`
