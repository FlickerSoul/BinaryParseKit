## 1. Foundation

- [ ] 1.1 Add `BitOrder` enum (`.msbFirst`, `.lsbFirst`) to `BitmaskParsable.swift`
- [ ] 1.2 Update `ExpressibleByBitmask` protocol to remove `OptionSet` constraint, add `associatedtype RawValue`
- [ ] 1.3 Update `BitmaskParsable` protocol to add `bitOrder` property with default implementation
- [ ] 1.4 Create `BitmaskUtils.swift` with `__extractBits` utility function
- [ ] 1.5 Add bitmask-related constants to `Constants.swift`

## 2. Struct Bitmask Macro

- [ ] 2.1 Update `@ParseBitmask` macro declaration in `BinaryParseKit.swift` with `bitCount`, `endianness`, `bitOrder` parameters
- [ ] 2.2 Update `@mask` macro declaration with `bitCount` parameter
- [ ] 2.3 Enhance `MaskMacroInfo.swift` with type information and start bit tracking
- [ ] 2.4 Implement `MaskMacroCollector.swift` visitor to collect `@mask` fields and compute bit positions
- [ ] 2.5 Create `ParseBitmaskMacroError.swift` with diagnostic error types
- [ ] 2.6 Implement `ConstructParseBitmaskMacro.swift` for struct bitmask generation
- [ ] 2.7 Add support for nested `BitmaskParsable` fields in struct bitmasks
- [ ] 2.8 Add `Printable` conformance generation for struct bitmasks

## 3. Enum Bitmask Macro

- [ ] 3.1 Create `ConstructEnumBitmaskMacro.swift` for enum bitmask handling
- [ ] 3.2 Implement struct shim generation (`__Bitmask_EnumName`)
- [ ] 3.3 Implement enum case mapping from raw values
- [ ] 3.4 Add validation for enum constraints (no associated values, raw values required)
- [ ] 3.5 Register `ConstructEnumBitmaskMacro` in `BinaryParseKitMacro.swift`

## 4. Testing

- [ ] 4.1 Add macro expansion tests for basic struct bitmask in `BinaryParseKitMacroTests`
- [ ] 4.2 Add macro expansion tests for enum bitmask with struct shim
- [ ] 4.3 Add macro expansion tests for multi-byte bitmask with endianness
- [ ] 4.4 Add macro expansion tests for nested bitmask fields
- [ ] 4.5 Add error case tests (bit count mismatch, enum with associated values, etc.)
- [ ] 4.6 Add end-to-end parsing tests in `BinaryParseKitTests` for struct bitmasks
- [ ] 4.7 Add end-to-end parsing tests for enum bitmasks
- [ ] 4.8 Add end-to-end tests for MSB-first vs LSB-first bit ordering

## 5. Documentation

- [ ] 5.1 Add DocC documentation for `@ParseBitmask` macro
- [ ] 5.2 Add DocC documentation for `@mask` macro
- [ ] 5.3 Add usage examples to `BinaryParseKit.swift` macro declarations
