import BinaryParseKit
import BinaryParsing

extension [UInt8]: SizedParsable {
    @lifetime(&input)
    public init(parsing input: inout ParserSpan, byteCount: Int) throws(ThrownParsingError) {
        var subSpan = try input.sliceSpan(byteCount: byteCount)
        self.init(parsingRemainingBytes: &subSpan)
    }
}

@ParseStruct
struct FileHeader {
    @parse(byteCount: 4, endianness: .big)
    let magic: UInt32

    @parse(byteCount: 2, endianness: .little)
    let version: UInt16

    @parse(endianness: .little)
    let fileSize: UInt32

    @skip(byteCount: 2, because: "reserved")
    @parse(byteCountOf: \Self.fileSize)
    let content: [UInt8]

    @parseRest
    let footer: [UInt8]
}

let binaryData: [UInt8] = [
    0x89, 0x50, 0x4E, 0x47, // Magic number (PNG signature)
    0x01, 0x00, // Version 1.0 (little endian)
    0x05, 0x00, 0x00, 0x00, // File size: 5 bytes (little endian)
    0x00, 0x00, // Reserved bytes (skipped)
    0x48, 0x65, 0x6C, 0x6C, 0x6F, // Content: "Hello"
    0xFF, 0xFE, // Footer data
]

let header = try FileHeader(parsing: binaryData)

print("Magic: 0x\(String(header.magic, radix: 16, uppercase: true))") // 0x89504E47
print("Version: \(header.version)") // 1
print("File Size: \(header.fileSize)") // 5
print("Content: \(String(bytes: header.content, encoding: .utf8)!)") // "Hello"
print("Footer: \(header.footer)")
