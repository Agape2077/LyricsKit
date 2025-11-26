import Foundation
import SWCompression

private let decodeKey: [UInt8] = [64, 71, 97, 119, 94, 50, 116, 71, 81, 54, 49, 45, 206, 210, 110, 105]
private let flagKey = "krc1".data(using: .ascii)!

func decryptKugouKrc(_ data: Data) -> String? {
    guard data.starts(with: flagKey) else {
        return nil
    }

    let decrypted = data.dropFirst(4).enumerated().map { index, byte in
        return byte ^ decodeKey[index & 0b1111]
    }

    // 关键修正：不要移除前2字节，SWCompression 需要完整的 Zlib 头
    // decrypted.removeFirst(2) 
    
    guard let unarchivedData = try? ZlibArchive.unarchive(archive: Data(decrypted)) else {
        return nil
    }

    return String(bytes: unarchivedData, encoding: .utf8)
}
