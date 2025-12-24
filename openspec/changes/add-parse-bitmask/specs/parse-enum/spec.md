# ParseEnum Macro Specification Delta

## ADDED Requirements

### Requirement: Bitmask Associated Value Parsing with @parseBitmask

Enum cases with associated values SHALL support `@parseBitmask` to parse bitmask values with byte-boundary padding.

**Constraints:**
- The associated value type MUST conform to `BitmaskParsable`
- Bytes consumed = ceil(valueType.bitCount / 8)
- Each `@parseBitmask` associated value is independently padded to the next byte boundary

#### Scenario: Associated value bitmask parsing
- **GIVEN** an enum case:
  ```swift
  @matchAndTake(byte: 0x01)
  @parseBitmask
  case withFlags(Flags)  // Flags.bitCount = 6
  ```
- **WHEN** parsing bytes `[0x01, 0b11010000, ...]`
- **THEN** byte `0x01` is matched and consumed
- **AND** the associated `Flags` value SHALL be parsed from the next 6 bits
- **AND** 1 byte SHALL be consumed for the associated value (padded from 6 bits to 8)

#### Scenario: Multiple bitmask associated values
- **GIVEN** an enum case:
  ```swift
  @matchAndTake(byte: 0x02)
  @parseBitmask
  @parseBitmask
  case twoFlags(A, B)  // A.bitCount = 4, B.bitCount = 6
  ```
- **WHEN** parsing bytes `[0x02, 0xF0, 0xFC, ...]`
- **THEN** byte `0x02` is matched and consumed
- **AND** `A` consumes 1 byte (4 bits padded to 8)
- **AND** `B` consumes 1 byte (6 bits padded to 8)

#### Scenario: Type assertion for BitmaskParsable
- **WHEN** an associated value uses `@parseBitmask`
- **THEN** the generated code includes `__assertBitmaskParsable(ValueType.self)`

#### Scenario: Insufficient bytes error
- **GIVEN** a bitmask associated value requiring 2 bytes
- **WHEN** the buffer has only 1 byte remaining after matching
- **THEN** parsing SHALL throw an error
