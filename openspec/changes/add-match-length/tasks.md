## 1. Core Implementation

- [ ] 1.1 Add `@match(length:)` macro declaration in `Sources/BinaryParseKit/BinaryParseKit.swift`
- [ ] 1.2 Add `__matchLength(length:in:)` utility function in `Sources/BinaryParseKit/Utils/ParsingUtils.swift`
- [ ] 1.3 Add `matchLength` constant in `Sources/BinaryParseKitMacros/Macros/Supports/Constants.swift`

## 2. Macro Processing

- [ ] 2.1 Extend `EnumCaseMatchAction` in `EnumCaseParseInfo.swift` with `matchLength: ExprSyntax?` property
- [ ] 2.2 Add `parseMatchLength(from:)` factory method to parse `length:` argument
- [ ] 2.3 Update `MacroAttributeCollector.swift` to detect and handle `@match(length:)` attribute
- [ ] 2.4 Add validation in `ParseEnumCase.swift` to ensure mutual exclusivity of byte-based and length-based matching

## 3. Code Generation

- [ ] 3.1 Update `ConsructParseEnumMacro.swift` to generate `__matchLength()` calls for length matching
- [ ] 3.2 Update printer extension to handle length match in `bytes:` field

## 4. Testing

- [ ] 4.1 Add macro expansion tests for `@match(length:)` in `BinaryParseKitMacroTests`
- [ ] 4.2 Add diagnostic test for mixed matching strategies error
- [ ] 4.3 Add end-to-end parsing tests in `BinaryParseKitTests`
