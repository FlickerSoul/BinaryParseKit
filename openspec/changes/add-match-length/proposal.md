# Change: Add Length-Based Enum Case Matching

## Why

Currently, enum cases can only match by byte patterns (`@match(byte:)`, `@match(bytes:)`) or raw values (`@match()`). Some binary formats determine the variant based on remaining data length rather than a discriminator byte pattern. This requires a new matching strategy.

## What Changes

- Add `@match(length:)` macro that matches when remaining buffer bytes equals the specified length exactly
- Non-consuming match (buffer position does not advance)
- Can be combined with associated value parsing via `@parse()` macros

## Impact

- Affected specs: `parse-enum`
- Affected code:
  - `Sources/BinaryParseKit/BinaryParseKit.swift` - macro declaration
  - `Sources/BinaryParseKit/Utils/ParsingUtils.swift` - utility function
  - `Sources/BinaryParseKitMacros/Macros/Supports/Constants.swift` - constant
  - `Sources/BinaryParseKitMacros/Macros/ParseEnum/EnumCaseParseInfo.swift` - match action
  - `Sources/BinaryParseKitMacros/Macros/Supports/MacroAttributeCollector.swift` - attribute parsing
  - `Sources/BinaryParseKitMacros/Macros/ParseEnum/ConstructParseEnumMacro.swift` - code generation
