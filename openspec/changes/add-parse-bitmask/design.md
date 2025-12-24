# Design: Bitmask Parsing

## Context

Binary formats often pack multiple values into bit fields. For example, a network packet header might use 4 bits for version, 4 bits for header length, etc. This design enables declarative parsing of such structures while maintaining type safety.

## Goals / Non-Goals

### Goals
- Enable declarative bitmask parsing with `@parseBitmask` in structs/enums
- Provide `@ParseBitmask` macro for defining custom bitmask types
- Support arbitrary bit widths via `RawBits` struct
- Maintain consistency with existing parsing patterns

### Non-Goals
- Bit-level endianness control (bits within bytes follow MSB-first ordering)
- Cross-byte bit fields within `@parseBitmask` (each field is padded independently)

## Decisions

### Decision 1: Protocol Hierarchy

Two protocols govern bitmask types:

**`ExpressibleByRawBits`** - For types that can be initialized from raw bits:
```swift
protocol ExpressibleByRawBits {
    init(from bits: RawBits) throws
}
```

**`BitmaskParsable`** - For types that know their own bit count (extends `ExpressibleByRawBits`):
```swift
protocol BitmaskParsable: ExpressibleByRawBits {
    static var bitCount: Int { get }
}
```

**Usage in `@ParseBitmask`:**
```swift
@ParseBitmask
struct Test {
    @mask(bitCount: 2)
    let a: A  // A must conform to ExpressibleByRawBits

    @mask(bitCount: 4)
    let b: B  // B must conform to ExpressibleByRawBits

    @mask
    let c: C  // C must conform to BitmaskParsable (has bitCount)

    @mask(bitCount: 4)
    let d: D  // D must conform to ExpressibleByRawBits
}
```

**Rationale:** Separating these protocols allows flexibility:
- Types with explicit `@mask(bitCount:)` only need `ExpressibleByRawBits`
- Types with implicit `@mask` (no bitCount) need `BitmaskParsable` to provide their bit count

### Decision 2: Padding Strategy for `@parseBitmask` Fields

When `@parseBitmask` is used in `@ParseStruct` or `@ParseEnum`, each bitmask field is independently padded to the next byte boundary.

**Rationale:** This matches common binary format conventions where bit fields are typically byte-aligned at field boundaries. It also simplifies implementation and makes the byte consumption predictable.

**Example:**
```swift
@ParseStruct
struct Example {
    @parseBitmask let a: A  // 2 bits -> consumes 1 byte
    @parseBitmask let b: B  // 4 bits -> consumes 1 byte
}
// Total: 2 bytes
```

### Decision 3: Consecutive Bits in `@ParseBitmask`

Within a `@ParseBitmask` struct, fields annotated with `@mask` are packed consecutively without intermediate padding. Padding only occurs at the end to reach a byte boundary.

**Rationale:** This allows efficient packing of multiple sub-fields within a single bitmask type.

**Example:**
```swift
@ParseBitmask
struct Flags {
    @mask(bitCount: 2) let a: UInt8  // bits 0-1
    @mask(bitCount: 4) let b: UInt8  // bits 2-5
    @mask(bitCount: 4) let c: UInt8  // bits 6-9
}
// bitCount = 10, consumes 2 bytes when used with @parseBitmask
```

### Decision 4: Bit Ordering

Bits are read MSB-first (most significant bit first) within each byte. The first field occupies the most significant bits of the first byte.

**Rationale:** MSB-first is the convention for network protocols and many binary formats.

**Example:**
```
Byte:     0b11010011
Field A (2 bits): 0b11 = 3
Field B (4 bits): 0b0100 = 4
Field C (2 bits): 0b11 = 3
```

### Decision 5: RawBits Structure

`RawBits` uses Swift 6.2's `RawSpan` for storage, providing efficient memory access and arbitrary bit widths.

```swift
struct RawBits {
    private(set) public var size: Int         // Total number of valid bits
    private static let BitsPerWord = 8
    fileprivate(set) public var span: RawSpan // Storage, MSB-first
}
```

**Rationale:** Using `RawSpan` aligns with the project's use of Swift 6.2 features and integrates naturally with the existing byte-based parsing infrastructure.

**Alternatives Considered:**
- `Data` storage: Rejected due to less efficient bit manipulation

## Risks / Trade-offs

### Trade-off: Per-field Padding vs. Packed Parsing
The decision to pad each `@parseBitmask` field to byte boundaries simplifies the implementation but means users cannot parse truly packed cross-struct bit fields. Users who need packed parsing should use a single `@ParseBitmask` type that encompasses all the bit fields.

**Mitigation:** Document this behavior clearly and provide examples of using `@ParseBitmask` for packed scenarios.

### Risk: Performance Overhead
Bit manipulation is inherently more complex than byte-aligned parsing.

**Mitigation:** Keep generated code minimal and delegate to optimized utility functions.

## Migration Plan

No migration needed. This is a new feature with no breaking changes to existing APIs.

## Open Questions

None at this time.
