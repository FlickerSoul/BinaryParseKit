# ParseBitmask Macro Specification

## Purpose

The `@ParseBitmask` macro automatically generates bitmask parsing code for Swift structs. It enables declarative definition of bit-packed data structures, generating conformance to `BitmaskParsable` protocol.

## ADDED Requirements

### Requirement: ExpressibleByRawBits Protocol

The `ExpressibleByRawBits` protocol SHALL define types that can be initialized from raw bits.

**Required Members:**
- `init(from bits: RawBits) throws` - Initializer that constructs the type from raw bits

#### Scenario: Primitive type conformance
- **WHEN** `UInt8` conforms to `ExpressibleByRawBits`
- **AND** `init(from:)` is called with a `RawBits` containing value `5`
- **THEN** the resulting `UInt8` SHALL be `5`

#### Scenario: Insufficient bits error
- **WHEN** `init(from:)` is called with a `RawBits` that has fewer bits than needed
- **THEN** parsing SHALL throw an error

### Requirement: BitmaskParsable Protocol

The `BitmaskParsable` protocol SHALL extend `ExpressibleByRawBits` to include bit count information.

**Required Members:**
- `static var bitCount: Int { get }` - The number of bits this type consumes

#### Scenario: Custom bitmask type
- **WHEN** a type conforms to `BitmaskParsable` with `bitCount = 6`
- **AND** `@parseBitmask` is used to parse this type
- **THEN** 6 bits SHALL be read (padded to 1 byte)

### Requirement: ParseBitmask Declaration Macro

The `@ParseBitmask` macro SHALL be an attached extension macro that generates `BitmaskParsable` protocol conformance for structs.

#### Scenario: Basic bitmask struct
- **WHEN** a struct is annotated with `@ParseBitmask`
- **AND** it contains fields with `@mask` attributes
- **THEN** the macro generates `BitmaskParsable` conformance
- **AND** generates `static var bitCount: Int` as the sum of all field bit counts
- **AND** generates `init(from bits: RawBits) throws`

#### Scenario: Non-struct type error
- **WHEN** the `@ParseBitmask` macro is applied to a non-struct type
- **THEN** the macro emits a diagnostic error

### Requirement: Mask Attribute with Explicit Bit Count

Fields annotated with `@mask(bitCount:)` SHALL extract the specified number of bits.

**Parameter:**
- `bitCount: Int` - The number of bits to extract for this field

**Constraint:**
- The field type MUST conform to `ExpressibleByRawBits`

#### Scenario: Explicit bit count field
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask
  struct Flags {
      @mask(bitCount: 4)
      let version: UInt8
  }
  ```
- **WHEN** parsing bits `0b1010....`
- **THEN** `version` SHALL be `10` (0b1010)

#### Scenario: Type assertion for ExpressibleByRawBits
- **WHEN** a field uses `@mask(bitCount:)`
- **THEN** the generated code includes `__assertExpressibleByRawBits(FieldType.self)`

### Requirement: Mask Attribute with Inferred Bit Count

Fields annotated with `@mask` (no arguments) SHALL use the field type's `bitCount`.

**Constraint:**
- The field type MUST conform to `BitmaskParsable`

#### Scenario: Inferred bit count field
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask
  struct Outer {
      @mask
      let inner: Inner  // Inner.bitCount = 6
  }
  ```
- **WHEN** the macro expands
- **THEN** `Outer.bitCount` SHALL include `Inner.bitCount` (6 bits)

#### Scenario: Type assertion for BitmaskParsable
- **WHEN** a field uses `@mask` without arguments
- **THEN** the generated code includes `__assertBitmaskParsable(FieldType.self)`

### Requirement: Consecutive Bit Packing

Within a `@ParseBitmask` struct, fields SHALL be packed consecutively without intermediate padding.

#### Scenario: Multiple consecutive fields
- **GIVEN** a struct with:
  ```swift
  @ParseBitmask
  struct Packed {
      @mask(bitCount: 2) let a: UInt8
      @mask(bitCount: 4) let b: UInt8
      @mask(bitCount: 4) let c: UInt8
  }
  ```
- **THEN** `Packed.bitCount` SHALL be `10` (2 + 4 + 4)
- **AND** field `a` occupies bits 0-1
- **AND** field `b` occupies bits 2-5
- **AND** field `c` occupies bits 6-9

### Requirement: Bit Ordering

Bits SHALL be read MSB-first (most significant bit first) within each byte.

#### Scenario: MSB-first bit extraction
- **GIVEN** a byte `0b11010011`
- **AND** extracting 2 bits for field A, then 4 bits for field B, then 2 bits for field C
- **THEN** field A SHALL be `0b11` (3)
- **AND** field B SHALL be `0b0100` (4)
- **AND** field C SHALL be `0b11` (3)

### Requirement: Mask Attribute Requirement

All non-computed stored properties in a `@ParseBitmask` struct MUST have a `@mask` attribute.

#### Scenario: Missing mask attribute error
- **WHEN** a stored property lacks a `@mask` attribute
- **THEN** the macro emits a diagnostic error

### Requirement: Type Annotation Requirement

All fields with `@mask` attributes MUST have explicit type annotations.

#### Scenario: Missing type annotation error
- **WHEN** a field like `@mask(bitCount: 4) let value` lacks a type annotation
- **THEN** the macro emits a diagnostic error
