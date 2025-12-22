## ADDED Requirements

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

## MODIFIED Requirements

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

#### Scenario: Match attribute ordering
- **WHEN** a case has `@parse()` before `@match()`
- **THEN** the macro emits a diagnostic error requiring match macro first
