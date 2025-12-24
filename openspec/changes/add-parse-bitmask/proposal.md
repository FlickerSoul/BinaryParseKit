# Change: Add Bitmask Parsing Support

## Why

Binary formats frequently pack multiple values into bit fields within bytes. Currently, BinaryParseKit only supports byte-aligned parsing, requiring manual bit manipulation for packed data. Adding bitmask parsing enables declarative parsing of bit-level structures, maintaining the library's goal of making binary parsing easy and type-safe.

## What Changes

- **NEW** `@parseBitmask` property macro for parsing bitmask fields in `@ParseStruct` and `@ParseEnum`
- **NEW** `ExpressibleByRawBits` protocol with initializer from `RawBits`:
  ```swift
  protocol ExpressibleByRawBits {
      init(from bits: RawBits) throws
  }
  ```
- **NEW** `BitmaskParsable` protocol extending `ExpressibleByRawBits` with `static var bitCount: Int`
- **NEW** `RawBits` struct for arbitrary-width bit storage using Swift 6.2 `RawSpan`:
  ```swift
  struct RawBits {
      private(set) public var size: Int
      private static let BitsPerWord = 8
      fileprivate(set) public var span: RawSpan
  }
  ```
- **NEW** `@ParseBitmask` declaration macro for defining bitmask-conforming structs
- **NEW** `@mask(bitCount:)` property macro for specifying bit counts within `@ParseBitmask` structs
  - Types used with explicit `bitCount` must conform to `ExpressibleByRawBits`
  - Types used with `@mask` (no bitCount) must conform to `BitmaskParsable`
- **NEW** Padding behavior: `@parseBitmask` fields consume bytes up to the next byte boundary
- **NEW** Error handling: Parsing throws error when insufficient bits available

## Impact

- Affected specs: `parse-struct`, `parse-enum` (add `@parseBitmask` support)
- New capability: `parse-bitmask` (new spec for bitmask definitions)
- Affected code:
  - `BinaryParseKitMacros`: New macros implementation
  - `BinaryParseKit`: New protocols, `RawBits` struct, and utility functions
  - Tests: Macro tests and end-to-end tests

## Examples

### Using `@parseBitmask` in a struct
```swift
@ParseStruct
struct Header {
    @parseBitmask
    let flags: Flags  // Flags.bitCount = 6, consumes 1 byte (padded)

    @parseBitmask
    let mode: Mode    // Mode.bitCount = 12, consumes 2 bytes (padded)
}
```

### Consecutive bitmask fields with padding
```swift
@ParseStruct
struct Packet {
    @parseBitmask
    let a: A  // 2 bits, consumes 1 byte (padded to 8)

    @parseBitmask
    let b: B  // 4 bits, consumes 1 byte (padded to 8)
}
// Total: 2 bytes consumed
```

### Defining a bitmask type with `@ParseBitmask`
```swift
@ParseBitmask
struct Flags {
    @mask(bitCount: 2)
    let priority: UInt8    // UInt8: ExpressibleByRawBits

    @mask(bitCount: 4)
    let channel: UInt8     // UInt8: ExpressibleByRawBits

    @mask
    let nested: NestedFlags  // NestedFlags: BitmaskParsable (uses NestedFlags.bitCount)

    @mask(bitCount: 4)
    let version: UInt8     // UInt8: ExpressibleByRawBits
}
// Fields are consecutive: priority(2) + channel(4) + nested.bitCount + version(4)
```
