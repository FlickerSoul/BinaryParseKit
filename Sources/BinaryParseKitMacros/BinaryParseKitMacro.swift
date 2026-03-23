import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BinaryParseKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EmptyPeerMacro.self,
        ConstructStructParseMacro.self,
        ConstructStructParseBodyMacro.self,
        ConstructEnumParseMacro.self,
        ConstructEnumParseBodyMacro.self,
        ConstructParseBitmaskMacro.self,
        ConstructParseBitmaskBodyMacro.self,
    ]
}
