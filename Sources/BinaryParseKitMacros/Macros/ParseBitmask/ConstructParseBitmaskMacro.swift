//
//  ConstructParseBitmaskMacro.swift
//  BinaryParseKit
//
//  Created by Larry Zeng on 11/28/25.
//
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Main Macro

public struct ConstructParseBitmaskMacro: ExtensionMacro, PeerMacro {
    // MARK: - ExtensionMacro

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo _: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        // Route to appropriate handler based on declaration type
        if let structDeclaration = declaration.as(StructDeclSyntax.self) {
            return try expandStructBitmask(
                node: node,
                structDeclaration: structDeclaration,
                type: type,
                context: context,
            )
        } else if let enumDeclaration = declaration.as(EnumDeclSyntax.self) {
            return try expandEnumBitmask(
                node: node,
                enumDeclaration: enumDeclaration,
                type: type,
                context: context,
            )
        } else {
            throw ParseBitmaskMacroError.unsupportedDeclarationType
        }
    }

    // MARK: - PeerMacro (for enum struct shim generation)

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
    ) throws -> [DeclSyntax] {
        // Only generate peer for enums (the struct shim)
        guard let enumDeclaration = declaration.as(EnumDeclSyntax.self) else {
            return []
        }

        return try generateEnumStructShim(
            node: node,
            enumDeclaration: enumDeclaration,
            context: context,
        )
    }
}

// MARK: - Struct Bitmask Expansion

private func expandStructBitmask(
    node: AttributeSyntax,
    structDeclaration: StructDeclSyntax,
    type: some TypeSyntaxProtocol,
    context: some MacroExpansionContext,
) throws -> [ExtensionDeclSyntax] {
    let type = type.trimmed

    // Extract accessor info
    let accessorInfo = try extractAccessor(
        from: node,
        attachedTo: structDeclaration,
        in: context,
    )

    // Collect @mask fields
    let collector = MaskMacroCollector(context: context)
    collector.walk(structDeclaration)
    try collector.validate()

    // Parse macro parameters
    let params = try ParseBitmaskParams(from: node)

    // Compute bit positions and validate
    let computedBitCount = try collector.computeBitPositions()
    let totalBitCount: Int

    if let specifiedBitCount = params.bitCount {
        // Validate specified bit count matches computed
        if computedBitCount != specifiedBitCount {
            throw ParseBitmaskMacroError.bitCountMismatch(
                expected: specifiedBitCount,
                actual: computedBitCount,
            )
        }
        totalBitCount = specifiedBitCount
    } else {
        totalBitCount = computedBitCount
    }

    // Validate endianness for multi-byte bitmasks
    let byteCount = (totalBitCount + 7) / 8
    if byteCount > 1, params.endianness == nil {
        throw ParseBitmaskMacroError.missingEndiannessForMultiByte(bitCount: totalBitCount)
    }

    // Generate BitmaskParsable extension
    let bitmaskParsableExtension = try generateBitmaskParsableExtension(
        type: type,
        accessorInfo: accessorInfo,
        maskFields: collector.maskInfoCollection,
        totalBitCount: totalBitCount,
        params: params,
    )

    // Generate Printable extension
    let printableExtension = try generatePrintableExtension(
        type: type,
        accessorInfo: accessorInfo,
        maskFields: collector.maskInfoCollection,
    )

    return [bitmaskParsableExtension, printableExtension]
}

// MARK: - Generate BitmaskParsable Extension

private func generateBitmaskParsableExtension(
    type: some TypeSyntaxProtocol,
    accessorInfo: AccessorInfo,
    maskFields: [MaskMacroInfo],
    totalBitCount: Int,
    params: ParseBitmaskParams,
) throws -> ExtensionDeclSyntax {
    let bitOrderExpr = switch params.bitOrder {
    case .msbFirst: "\(Constants.Bitmask.bitOrderMsbFirst)"
    case .lsbFirst: "\(Constants.Bitmask.bitOrderLsbFirst)"
    }

    let endiannessExpr = if let endianness = params.endianness {
        ".\(endianness)"
    } else {
        "nil"
    }

    // Determine the raw value type based on bit count
    let rawValueType = rawValueTypeForBitCount(totalBitCount)

    return try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.bitmaskParsableProtocol)") {
        // typealias RawValue
        "typealias RawValue = \(raw: rawValueType)"

        // static var bitCount
        try VariableDeclSyntax("\(accessorInfo.parsingAccessor) static var bitCount: Int") {
            "\(raw: totalBitCount)"
        }

        // static var endianness
        try VariableDeclSyntax("\(accessorInfo.parsingAccessor) static var endianness: Endianness?") {
            "\(raw: endiannessExpr)"
        }

        // static var bitOrder
        try VariableDeclSyntax(
            "\(accessorInfo.parsingAccessor) static var bitOrder: \(raw: Constants.Bitmask.bitOrderType)",
        ) {
            "\(raw: bitOrderExpr)"
        }

        // init(bitmask:) - bit extraction initializer
        try InitializerDeclSyntax(
            "\(accessorInfo.parsingAccessor) init(bitmask rawValue: RawValue) throws(BitmaskParsableError)",
        ) {
            generateBitmaskFieldExtraction(
                maskFields: maskFields,
                totalBitCount: totalBitCount,
            )
        }
    }
}

@CodeBlockItemListBuilder
private func generateBitmaskFieldExtraction(
    maskFields: [MaskMacroInfo],
    totalBitCount: Int,
) -> CodeBlockItemListSyntax {
    for field in maskFields {
        if let fieldBitCount = field.bitCount.value {
            // Generate assertion for ExpressibleByBitmask types (nested bitmasks)
            #"""
            // Extract `\#(field.name)` of type \#(field.type)
            \#(raw: Constants.Bitmask.assertExpressibleByBitmask)((\#(field.type)).self)
            """#

            #"""
            self.\#(field.name) = try \#(field.type)(
                bitmask: \#(raw: Constants.Bitmask.extractBits)(
                    from: rawValue,
                    startBit: \#(raw: field.startBit),
                    bitCount: \#(raw: fieldBitCount),
                    totalBitCount: \#(raw: totalBitCount),
                    bitOrder: Self.bitOrder
                )
            )
            """#
        }
    }
}

// MARK: - Generate Printable Extension

private func generatePrintableExtension(
    type: some TypeSyntaxProtocol,
    accessorInfo: AccessorInfo,
    maskFields: [MaskMacroInfo],
) throws -> ExtensionDeclSyntax {
    // Build field infos array before entering the result builder context
    var fieldInfos: [PrintableBitmaskFieldInfo] = []
    for field in maskFields {
        fieldInfos.append(.init(
            binding: field.name,
            bitCount: field.bitCount.value,
        ))
    }

    let fields = ArrayExprSyntax(elements: generateBitmaskPrintableFields(fieldInfos))

    return try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.printableProtocol)") {
        try FunctionDeclSyntax("\(accessorInfo.printingAccessor) func printerIntel() throws -> PrinterIntel") {
            #"""
            return .struct(
                .init(
                    fields: \#(fields)
                )
            )
            """#
        }
    }
}

// MARK: - Enum Bitmask Expansion

private func expandEnumBitmask(
    node: AttributeSyntax,
    enumDeclaration: EnumDeclSyntax,
    type: some TypeSyntaxProtocol,
    context _: some MacroExpansionContext,
) throws -> [ExtensionDeclSyntax] {
    let type = type.trimmed

    // Validate enum constraints
    try validateEnumForBitmask(enumDeclaration)

    // Get the raw value type
    guard let rawValueType = getEnumRawValueType(enumDeclaration) else {
        throw ParseBitmaskMacroError.enumWithoutRawValues
    }

    // Parse macro parameters
    let params = try ParseBitmaskParams(from: node)

    // Generate Parsable extension
    let parsableExtension = try generateEnumParsableExtension(
        type: type,
        enumDeclaration: enumDeclaration,
        rawValueType: rawValueType,
        params: params,
    )

    return [parsableExtension]
}

// MARK: - Generate Enum Struct Shim

private func generateEnumStructShim(
    node: AttributeSyntax,
    enumDeclaration: EnumDeclSyntax,
    context _: some MacroExpansionContext,
) throws -> [DeclSyntax] {
    // Validate enum constraints
    try validateEnumForBitmask(enumDeclaration)

    // Get the raw value type
    guard let rawValueType = getEnumRawValueType(enumDeclaration) else {
        throw ParseBitmaskMacroError.enumWithoutRawValues
    }

    // Parse macro parameters
    let params = try ParseBitmaskParams(from: node)

    let enumName = enumDeclaration.name.text
    let shimName = "__Bitmask_\(enumName)"

    // Determine bit count
    let bitCount = params.bitCount ?? inferBitCountFromType(rawValueType.description)

    let bitOrderExpr = switch params.bitOrder {
    case .msbFirst: "\(Constants.Bitmask.bitOrderMsbFirst)"
    case .lsbFirst: "\(Constants.Bitmask.bitOrderLsbFirst)"
    }

    let endiannessExpr = if let endianness = params.endianness {
        ".\(endianness)"
    } else {
        "nil"
    }

    // Validate endianness for multi-byte bitmasks
    if let bitCount, (bitCount + 7) / 8 > 1, params.endianness == nil {
        throw ParseBitmaskMacroError.missingEndiannessForMultiByte(bitCount: bitCount)
    }

    let shimStruct: DeclSyntax = """
    private struct \(raw: shimName): \(raw: Constants.Protocols.bitmaskParsableProtocol) {
        typealias RawValue = \(rawValueType)

        let rawValue: RawValue

        static var bitCount: Int { \(raw: bitCount ?? 8) }
        static var endianness: Endianness? { \(raw: endiannessExpr) }
        static var bitOrder: \(raw: Constants.Bitmask.bitOrderType) { \(raw: bitOrderExpr) }

        init(bitmask rawValue: RawValue) throws(\(raw: Constants.BinaryParsing.thrownParsingError)) {
            self.rawValue = rawValue
        }
    }
    """

    return [shimStruct]
}

// MARK: - Generate Enum Parsable Extension

private func generateEnumParsableExtension(
    type: some TypeSyntaxProtocol,
    enumDeclaration: EnumDeclSyntax,
    rawValueType _: TypeSyntax,
    params _: ParseBitmaskParams,
) throws -> ExtensionDeclSyntax {
    let enumName = enumDeclaration.name.text
    let shimName = "__Bitmask_\(enumName)"

    // Collect enum cases
    let cases = collectEnumCases(enumDeclaration)

    return try ExtensionDeclSyntax("extension \(type): \(raw: Constants.Protocols.parsableProtocol)") {
        try InitializerDeclSyntax(
            "public init(parsing span: inout \(raw: Constants.BinaryParsing.parserSpan)) throws(\(raw: Constants.BinaryParsing.thrownParsingError))",
        ) {
            // Parse using the struct shim
            "let shim = try \(raw: shimName)(parsing: &span)"

            // Switch on raw value to map to enum cases
            try SwitchExprSyntax("switch shim.rawValue") {
                for enumCase in cases {
                    if let rawValue = enumCase.rawValue {
                        SwitchCaseSyntax("case \(rawValue):") {
                            "self = .\(enumCase.name)"
                        }
                    }
                }

                // Default case throws error
                SwitchCaseSyntax("default:") {
                    "throw \(raw: Constants.BinaryParsing.thrownParsingError)(BitmaskParsableError.invalidEnumRawValue)"
                }
            }
        }
    }
}

// MARK: - Helper Types

/// Parsed parameters from @ParseBitmask attribute.
struct ParseBitmaskParams {
    var bitCount: Int?
    var endianness: String?
    var bitOrder: BitOrderValue = .msbFirst

    enum BitOrderValue {
        case msbFirst
        case lsbFirst
    }

    init(from attribute: AttributeSyntax) throws {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return
        }

        for argument in arguments {
            switch argument.label?.text {
            case "bitCount":
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    bitCount = Int(intLiteral.literal.text)
                }
            case "endianness":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    endianness = memberAccess.declName.baseName.text
                }
            case "bitOrder":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    let value = memberAccess.declName.baseName.text
                    bitOrder = value == "lsbFirst" ? .lsbFirst : .msbFirst
                }
            default:
                break
            }
        }
    }
}

/// Information about an enum case.
struct EnumCaseInfo {
    let name: TokenSyntax
    let rawValue: ExprSyntax?
}

// MARK: - Helper Functions

private func rawValueTypeForBitCount(_ bitCount: Int) -> String {
    if bitCount <= 8 {
        "UInt8"
    } else if bitCount <= 16 {
        "UInt16"
    } else if bitCount <= 32 {
        "UInt32"
    } else {
        "UInt64"
    }
}

private func inferBitCountFromType(_ typeName: String) -> Int? {
    switch typeName {
    case "UInt8", "Int8": 8
    case "UInt16", "Int16": 16
    case "UInt32", "Int32": 32
    case "UInt64", "Int64": 64
    default: nil
    }
}

private func validateEnumForBitmask(_ enumDecl: EnumDeclSyntax) throws {
    // Check for associated values
    for member in enumDecl.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            continue
        }

        for element in caseDecl.elements where element.parameterClause != nil {
            throw ParseBitmaskMacroError.enumWithAssociatedValues
        }
    }
}

private func getEnumRawValueType(_ enumDecl: EnumDeclSyntax) -> TypeSyntax? {
    guard let inheritanceClause = enumDecl.inheritanceClause else {
        return nil
    }

    for inheritedType in inheritanceClause.inheritedTypes {
        let typeName = inheritedType.type.description.trimmingCharacters(in: .whitespaces)
        // Check if it's a known integer type
        if ["UInt8", "UInt16", "UInt32", "UInt64", "Int8", "Int16", "Int32", "Int64"].contains(typeName) {
            return inheritedType.type
        }
    }

    return nil
}

private func collectEnumCases(_ enumDecl: EnumDeclSyntax) -> [EnumCaseInfo] {
    var cases: [EnumCaseInfo] = []

    for member in enumDecl.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            continue
        }

        for element in caseDecl.elements {
            cases.append(.init(
                name: element.name,
                rawValue: element.rawValue?.value,
            ))
        }
    }

    return cases
}

// MARK: - Printable Helpers

struct PrintableBitmaskFieldInfo {
    let binding: TokenSyntax
    let bitCount: Int?
}

@ArrayElementListBuilder
func generateBitmaskPrintableFields(_ infos: [PrintableBitmaskFieldInfo]) -> ArrayElementListSyntax {
    for info in infos {
        ArrayElementSyntax(
            expression:
            FunctionCallExprSyntax(callee: MemberAccessExprSyntax(name: "init")) {
                LabeledExprSyntax(
                    label: "byteCount",
                    expression: info.bitCount.map { ExprSyntax("\(raw: $0)") } ?? ExprSyntax("nil"),
                )
                LabeledExprSyntax(
                    label: "endianness",
                    expression: ExprSyntax("nil"),
                )
                LabeledExprSyntax(
                    label: "intel",
                    expression: ExprSyntax(
                        "try \(raw: Constants.UtilityFunctions.getPrintIntel)(\(info.binding))",
                    ),
                )
            },
        )
    }
}
