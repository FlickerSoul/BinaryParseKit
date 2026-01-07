import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BinaryParseKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EmptyPeerMacro.self,
        ConstructStructParseMacro.self,
        ConstructEnumParseMacro.self,
        ConstructParseBitmaskMacro.self,
    ]
}
