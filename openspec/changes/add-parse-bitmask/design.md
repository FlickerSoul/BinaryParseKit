## Context

BinaryParseKit provides macros for parsing binary data into Swift types. The existing `@ParseStruct` and `@ParseEnum` macros handle byte-level parsing. This change adds bit-level parsing support for bitmasks, a common pattern in binary protocols (network headers, file formats, hardware registers).

**Stakeholders:** Library users parsing protocols with bitmask fields.

**Constraints:**
- Must integrate with existing protocol hierarchy (Parsable, SizedParsable)
- Generated code should delegate to utility functions per project conventions
- Byte-aligned only (total bits must be multiple of 8)

## Goals / Non-Goals

**Goals:**
- Declarative bitmask parsing via `@ParseBitmask` macro
- Support both structs (combinable fields) and enums (exclusive patterns)
- Configurable bit ordering (MSB-first, LSB-first) and endianness
- Full nesting support for struct bitmasks

**Non-Goals:**
- Non-byte-aligned bitmasks (would complicate buffer management)
- OptionSet-style flag combining in this phase (enums map to exclusive patterns only)
- Associated values in enum bitmasks

## Decisions

### Decision 1: Remove OptionSet Constraint from ExpressibleByBitmask

**What:** Change `ExpressibleByBitmask` from `protocol ExpressibleByBitmask: OptionSet` to a standalone protocol with `associatedtype RawValue: BinaryInteger & BitwiseCopyable`.

**Why:** Structs with named fields don't fit the OptionSet pattern. Users want to define bitmasks like:
```swift
@ParseBitmask(bitCount: 8)
struct RGBA {
    @mask(bitCount: 2) let red: Int
    @mask(bitCount: 2) let green: Int
    ...
}
```
This doesn't map to OptionSet semantics.

**Alternatives considered:**
- Keep OptionSet and generate synthetic rawValue - overly complex, doesn't match user mental model
- Create separate protocol for struct bitmasks - fragments the protocol hierarchy

### Decision 2: Struct Shim for Enum Parsing

**What:** For enum bitmasks, generate a hidden struct (`__Bitmask_EnumName`) that captures the raw value, then map to enum cases in the Parsable initializer.

**Why:** Enums with raw values need parsing logic that:
1. Reads bytes into an integer
2. Validates the integer matches a known case
3. Returns the enum case

Generating a struct shim keeps the generated code pattern consistent with struct bitmasks and isolates the raw value handling.

**Generated pattern:**
```swift
@ParseBitmask(bitCount: 2)
enum Direction: UInt8 {
    case north = 0b00
    case east = 0b01
}

// Generated:
private struct __Bitmask_Direction: BitmaskParsable {
    let rawValue: UInt8
    init(bitmask rawValue: UInt8) { self.rawValue = rawValue }
    ...
}

extension Direction: Parsable {
    init(parsing span: inout ParserSpan) throws {
        let shim = try __Bitmask_Direction(parsing: &span)
        switch shim.rawValue {
        case 0b00: self = .north
        case 0b01: self = .east
        default: throw ...
        }
    }
}
```

### Decision 3: Bit Extraction via Utility Function

**What:** Create `__extractBits(from:startBit:bitCount:totalBitCount:bitOrder:)` utility function.

**Why:** Per project conventions, generated code should be minimal and delegate to utilities. Bit extraction logic is non-trivial (especially with bit order handling) and belongs in a testable utility.

### Decision 4: Default Bit Order is MSB-First

**What:** Default `bitOrder` to `.msbFirst` (most significant bit first).

**Why:** MSB-first matches typical protocol documentation where the first field listed corresponds to the high bits. This is the convention in network protocols (TCP/IP headers) and most hardware documentation.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Breaking change if existing code uses ExpressibleByBitmask with OptionSet | Low risk - protocol is new and unused. Add deprecation note in release. |
| Enum struct shim increases generated code | Acceptable - keeps enum parsing consistent and isolated |
| Bit order confusion between MSB/LSB | Clear documentation and explicit parameter when non-default needed |

## Open Questions

None at this time.
