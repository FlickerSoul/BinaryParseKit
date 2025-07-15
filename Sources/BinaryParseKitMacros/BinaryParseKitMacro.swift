import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BinaryParseKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ByteParsingMacro.self,
    ]
}
