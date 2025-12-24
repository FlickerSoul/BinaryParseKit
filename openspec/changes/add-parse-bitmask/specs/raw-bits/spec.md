# RawBits Specification

## Purpose

The `RawBits` struct provides arbitrary-width bit storage and manipulation for bitmask parsing operations.

## ADDED Requirements

### Requirement: RawBits Storage Type

The `RawBits` struct SHALL provide arbitrary-width bit storage for bitmask values.

**Properties:**
- `size: Int` - The number of valid bits stored
- `span: RawSpan` - The underlying byte storage

**Static Constants:**
- `BitsPerWord = 8` - Number of bits per byte (private)

#### Scenario: RawBits initialization
- **WHEN** a `RawBits` is created with 10 bits of data
- **THEN** `size` SHALL be `10`
- **AND** `span` SHALL contain at least 2 bytes

#### Scenario: RawBits with many bits
- **WHEN** a `RawBits` is created with 100 bits of data
- **THEN** `size` SHALL be `100`
- **AND** `span` SHALL contain at least 13 bytes

### Requirement: RawBits Slicing

The `RawBits` struct SHALL support extracting a contiguous range of bits as a new `RawBits` instance.

#### Scenario: Slice extraction
- **GIVEN** a `RawBits` with 16 bits: `0b1010110011001010`
- **WHEN** slicing bits 4 through 11 (8 bits)
- **THEN** the result SHALL be a new `RawBits` with `size = 8`
- **AND** the bits SHALL be `0b11001100`

#### Scenario: Slice from beginning
- **GIVEN** a `RawBits` with 10 bits
- **WHEN** slicing bits 0 through 3 (4 bits)
- **THEN** the result SHALL contain the first 4 bits

### Requirement: RawBits Equality

The `RawBits` struct SHALL conform to `Equatable` for comparing bit values.

#### Scenario: Equal RawBits
- **GIVEN** two `RawBits` instances with identical bits and size
- **WHEN** comparing with `==`
- **THEN** the result SHALL be `true`

#### Scenario: Different size inequality
- **GIVEN** two `RawBits` with different `size` values
- **WHEN** comparing with `==`
- **THEN** the result SHALL be `false`

### Requirement: RawBits Slice Equality with Offset

The `RawBits` struct SHALL support comparing a slice of bits against another `RawBits` starting at a given offset.

#### Scenario: Slice equality match
- **GIVEN** a `RawBits` A with bits `0b11110000`
- **AND** a `RawBits` B with bits `0b1111`
- **WHEN** comparing B against A at offset 0 with length 4
- **THEN** the result SHALL be `true`

#### Scenario: Slice equality mismatch
- **GIVEN** a `RawBits` A with bits `0b11110000`
- **AND** a `RawBits` B with bits `0b1111`
- **WHEN** comparing B against A at offset 4 with length 4
- **THEN** the result SHALL be `false`

### Requirement: RawBits Bitwise AND

The `RawBits` struct SHALL support bitwise AND operation.

#### Scenario: Bitwise AND operation
- **GIVEN** `RawBits` A with bits `0b1010`
- **AND** `RawBits` B with bits `0b1100`
- **WHEN** computing `A & B`
- **THEN** the result SHALL be `RawBits` with bits `0b1000`

#### Scenario: Bitwise AND with different sizes
- **GIVEN** `RawBits` A with 8 bits and `RawBits` B with 4 bits
- **WHEN** computing `A & B`
- **THEN** the result size SHALL be the minimum of the two sizes

### Requirement: RawBits Bitwise OR

The `RawBits` struct SHALL support bitwise OR operation.

#### Scenario: Bitwise OR operation
- **GIVEN** `RawBits` A with bits `0b1010`
- **AND** `RawBits` B with bits `0b1100`
- **WHEN** computing `A | B`
- **THEN** the result SHALL be `RawBits` with bits `0b1110`

### Requirement: RawBits Bitwise XOR

The `RawBits` struct SHALL support bitwise XOR operation.

#### Scenario: Bitwise XOR operation
- **GIVEN** `RawBits` A with bits `0b1010`
- **AND** `RawBits` B with bits `0b1100`
- **WHEN** computing `A ^ B`
- **THEN** the result SHALL be `RawBits` with bits `0b0110`
