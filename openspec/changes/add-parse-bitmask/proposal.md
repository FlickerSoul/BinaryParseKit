# Change: Add @ParseBitmask Macro for Bitmask Parsing

## Why

Binary protocols frequently use bitmasks to pack multiple fields into a single byte or multi-byte value. Currently, BinaryParseKit lacks native support for parsing bitmasks, requiring users to manually extract bits from parsed integers. This change adds a `@ParseBitmask` macro that automates bit-level field extraction, making bitmask parsing declarative and type-safe.

## What Changes

- Add `BitOrder` enum to control bit ordering within bytes (MSB-first or LSB-first)
- Update `ExpressibleByBitmask` protocol to remove `OptionSet` constraint (structs don't naturally conform to OptionSet)
- Implement `@ParseBitmask` macro for **structs** with `@mask(bitCount:)` field annotations
- Implement `@ParseBitmask` macro for **enums** by generating a hidden struct shim for parsing, then mapping to enum cases
- Add `__extractBits` utility function for bit extraction
- Support full nesting for structs (bitmask fields can be other BitmaskParsable types)
- Support multi-byte bitmasks with configurable endianness

## Impact

- Affected specs: New `parse-bitmask` capability
- Affected code:
  - `Sources/BinaryParseKit/Protocols/BitmaskParsable.swift` - Protocol updates
  - `Sources/BinaryParseKit/BinaryParseKit.swift` - Macro declarations
  - `Sources/BinaryParseKitMacros/Macros/ParseBitmask/` - Macro implementations
  - `Sources/BinaryParseKitMacros/Macros/Supports/` - Supporting types
