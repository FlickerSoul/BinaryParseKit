# Implementation Tasks

## 1. Core Types and Protocols

- [ ] 1.1 Implement `RawBits` struct in `BinaryParseKit` target
  - Properties: `size`, `span: RawSpan`
  - Static constant: `BitsPerWord = 8`
  - Bit extraction/manipulation methods
  - Slicing, equality, bitwise operations (AND, OR, XOR)

- [ ] 1.2 Implement `BitmaskParsable` protocol in `BinaryParseKit` target
  - `static var bitCount: Int { get }`
  - `init(from bits: RawBits) throws`

- [ ] 1.3 Add conformance of primitive types to `BitmaskParsable` (e.g., `UInt8`, `UInt16`, etc.)

## 2. Macro Implementation

- [ ] 2.1 Implement `@ParseBitmask` declaration macro in `BinaryParseKitMacros`
  - Generate `BitmaskParsable` conformance
  - Calculate total `bitCount` from fields
  - Generate initializer from `RawBits`

- [ ] 2.2 Implement `@mask(bitCount:)` property macro in `BinaryParseKitMacros`
  - Support explicit bit count specification
  - Support inferring bit count from `BitmaskParsable` type

- [ ] 2.3 Implement `@parseBitmask` property macro in `BinaryParseKitMacros`
  - For use in `@ParseStruct` and `@ParseEnum`
  - Handle byte-boundary padding

## 3. Integration with Existing Macros

- [ ] 3.1 Update `@ParseStruct` to recognize `@parseBitmask` fields
  - Generate parsing code that respects byte-boundary padding
  - Update `Parsable` conformance generation

- [ ] 3.2 Update `@ParseEnum` to recognize `@parseBitmask` for associated values
  - Support bitmask parsing in enum cases

## 4. Utility Functions

- [ ] 4.1 Add bit extraction utility functions in `BinaryParseKit`
  - `__assertBitmaskParsable(_:)` for compile-time validation
  - Bit manipulation helpers for `RawBits`

## 5. Error Handling

- [ ] 5.1 Add error case for insufficient bits during parsing
  - Extend `BinaryParseKitError` with appropriate case

## 6. Testing

- [ ] 6.1 Add macro expansion tests in `BinaryParseKitMacroTests`
  - `@ParseBitmask` expansion tests
  - `@mask` expansion tests
  - `@parseBitmask` expansion tests

- [ ] 6.2 Add end-to-end parsing tests in `BinaryParseKitTests`
  - Test bitmask parsing with various bit counts
  - Test byte-boundary padding behavior
  - Test consecutive bitmask fields
  - Test error handling for insufficient bits

## 7. Documentation

- [ ] 7.1 Add DOCC documentation for new types and macros
