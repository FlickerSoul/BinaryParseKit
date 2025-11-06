import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BinaryParseKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SkipParsingMacro.self,
        ByteParsingMacro.self,
        ConstructStructParseMacro.self,
        ConstructEnumParseMacro.self,
    ]
}
