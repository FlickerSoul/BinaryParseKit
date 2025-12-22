# Project Context

## Purpose

This project aims to make binary parsing in Swift easy and type-safe by leveraging Swift's macros and protocols. It provides developers with tools to define binary data structures declaratively, automatically generating parsing logic and ensuring accuracy and maintainability.

## Tech Stack

- Swift Macros
- Swift DOCC
- swift-binary-parsing
- swift-macro-testing
- swift-testing

## Project Conventions

### Code Style

The code style follows the standard Swift guidelines and the .swift-format.conf and .swift-lint.yml configurations provided in the repository. Please ensure to run the formatter and linter before committing code.

### Architecture Patterns

The package functionality mainly consists from 3 parts: a macro target `BinaryParseKitMacros`, a public API target `BinaryParseKit`, a shared target `BinaryParseKitCommons` used internally in `BinaryParseKitMacros` and `BinaryParseKit`. In addition, the package has two test targets: `BinaryParseKitMacroTests` that tests macro generation, and `BinaryParseKitTests` serving as end-to-end tests for public API and parsing. The package also provides a executable target `BinaryParseKitClient` as an example client using the library.

The generated code from macros in `BinaryParseKitMacros` should be minimal, and delegate heavy lifting to utility functions (e.g. `__match`, `__assertParsable`, etc.) defined in `BinaryParseKit` target. Please define necessary utility code when needed to keep generated code simple, clean, and maintainable.

Each type of parsing should have a dedicated declaration macro (e.g. `@ParseStruct` and `@ParseEnum`), and each parsing behavior should have a dedicated property wrapper macro (e.g. `@parse`, `@match`, `@skip`, etc.). This separation of concerns keeps the code modular and easier to understand.

### Testing Strategy

Each macro feature must be tested in `BinaryParseKitMacroTests` using `swift-macro-testing` to ensure the generated code is correct. The public API (including macro and parsing features) must be tested in `BinaryParseKitTests` with various test cases covering different parsing scenarios, edge cases, and error handling.

### Git Workflow

- Branches should be prefixed with `feature/`, `fix/`, or `refactor/` depending on the type of work.
- Pull requests must be reviewed by the owner before merging.
- Pull requests are squashed when merging to keep the commit history clean. Therefore, please keep each PR small and focused on a single task.

## Domain Context

- This library builds on top of the [`swift-binary-parsing`](https://github.com/apple/swift-binary-parsing) package.
- Parsing is mainly done using the new feature `Span` and `MutableSpan` from Swift 6.2.

## Important Constraints

N/A

## External Dependencies

N/A
