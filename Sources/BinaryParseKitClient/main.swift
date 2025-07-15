import BinaryParseKit
import BinaryParseKitCommons
import BinaryParsing

@ParseStruct
struct Header {
    @parse(byteCount: 1, endianness: .big)
    let a: Int

    @parse(endianness: .little)
    let b: Int32

    @parse(endianness: .big)
    let d: Float16
}

do {
    let header = try Header(parsing: [1, 2, 3, 4, 5, 6, 7] as [UInt8])
    print(header)
} catch {
    print(error)
}
