# ParseStruct Macro Specification Delta

## ADDED Requirements

### Requirement: Bitmask Field Parsing with @parseBitmask

Fields annotated with `@parseBitmask` SHALL be parsed as bitmask values with byte-boundary padding.

**Constraints:**
- The field type MUST conform to `BitmaskParsable`
- Bytes consumed = ceil(fieldType.bitCount / 8)
- Each `@parseBitmask` field is independently padded to the next byte boundary

#### Scenario: Single bitmask field parsing
- **GIVEN** a struct with:
  ```swift
  @ParseStruct
  struct Header {
      @parseBitmask
      let flags: Flags  // Flags.bitCount = 6
  }
  ```
- **WHEN** parsing bytes `[0b11010000, ...]`
- **THEN** `flags` SHALL be parsed from the first 6 bits
- **AND** 1 byte SHALL be consumed (padded from 6 bits to 8)

#### Scenario: Multiple bitmask fields with padding
- **GIVEN** a struct with:
  ```swift
  @ParseStruct
  struct Packet {
      @parseBitmask
      let a: A  // A.bitCount = 2
      @parseBitmask
      let b: B  // B.bitCount = 4
  }
  ```
- **WHEN** parsing bytes `[0xC0, 0xF0, ...]`
- **THEN** `a` SHALL consume 1 byte (2 bits padded to 8)
- **AND** `b` SHALL consume 1 byte (4 bits padded to 8)
- **AND** total bytes consumed SHALL be 2

#### Scenario: Bitmask field exceeding one byte
- **GIVEN** a struct with:
  ```swift
  @ParseStruct
  struct Header {
      @parseBitmask
      let extended: Extended  // Extended.bitCount = 12
  }
  ```
- **WHEN** parsing bytes `[0xAB, 0xC0, ...]`
- **THEN** 2 bytes SHALL be consumed (12 bits padded to 16)

#### Scenario: Type assertion for BitmaskParsable
- **WHEN** a field uses `@parseBitmask`
- **THEN** the generated code includes `__assertBitmaskParsable(FieldType.self)`

#### Scenario: Insufficient bytes error
- **GIVEN** a bitmask field requiring 2 bytes
- **WHEN** the buffer has only 1 byte remaining
- **THEN** parsing SHALL throw an error
