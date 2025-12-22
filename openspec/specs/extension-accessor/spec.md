# ExtensionAccessor Specification

## Purpose

The `ExtensionAccessor` type provides a mechanism for controlling the access level of generated extension members in parsing and printing macros. It enables fine-grained control over the visibility of generated `init(parsing:)` initializers and `printerIntel()` methods.

## Requirements

### Requirement: ExtensionAccessor Enum Definition

The `ExtensionAccessor` enum SHALL define all possible access level options for generated extension members.

**Cases:**
- `.public` - Public access level
- `.package` - Package access level
- `.internal` - Internal access level (default Swift visibility)
- `.fileprivate` - File-private access level
- `.private` - Private access level
- `.follow` - Inherits the access level from the annotated type

#### Scenario: All access levels available
- **WHEN** a macro accepts an `ExtensionAccessor` parameter
- **THEN** all six access level options SHALL be available for selection

### Requirement: Follow Access Level Behavior

The `.follow` case SHALL cause the generated extension member to inherit the access level of the type being extended.

#### Scenario: Public type with follow accessor
- **WHEN** a `public struct` uses a macro with `parsingAccessor: .follow`
- **THEN** the generated `init(parsing:)` SHALL have `public` access

#### Scenario: Internal type with follow accessor
- **WHEN** an `internal struct` uses a macro with `parsingAccessor: .follow`
- **THEN** the generated `init(parsing:)` SHALL have `internal` access

#### Scenario: Private type with follow accessor
- **WHEN** a `private struct` uses a macro with `parsingAccessor: .follow`
- **THEN** the generated `init(parsing:)` SHALL have `private` access

### Requirement: Explicit Access Level Override

Explicit `ExtensionAccessor` values (non-`.follow`) SHALL override the type's access level for the generated member.

#### Scenario: Public type with internal override
- **WHEN** a `public struct` uses a macro with `parsingAccessor: .internal`
- **THEN** the generated `init(parsing:)` SHALL have `internal` access regardless of the struct being public

#### Scenario: Internal type with public override
- **WHEN** an `internal struct` uses a macro with `printingAccessor: .public`
- **THEN** the generated `printerIntel()` SHALL have `public` access

### Requirement: Default Parameter Value

The default value for `ExtensionAccessor` parameters in macros SHALL be `.follow`.

#### Scenario: Omitted accessor parameter
- **WHEN** a macro is used without specifying accessor parameters
- **THEN** the accessor SHALL default to `.follow`
- **AND** the generated members SHALL inherit the type's access level

### Requirement: Independent Accessor Control

Macros that generate multiple extension members SHALL support independent accessor control for each member.

#### Scenario: Different accessors for parsing and printing
- **WHEN** `@ParseStruct(parsingAccessor: .internal, printingAccessor: .public)` is applied
- **THEN** the generated `init(parsing:)` SHALL have `internal` access
- **AND** the generated `printerIntel()` SHALL have `public` access

#### Scenario: Mixed follow and explicit
- **WHEN** `@ParseEnum(parsingAccessor: .follow, printingAccessor: .private)` is applied to a `public enum`
- **THEN** the generated `init(parsing:)` SHALL have `public` access (following the enum)
- **AND** the generated `printerIntel()` SHALL have `private` access (explicit override)
