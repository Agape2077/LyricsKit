import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(FoundationXML)
import FoundationXML
#endif
import Foundation

struct KugouResponseSingleLyrics: Decodable {
    let content: Data
    let fmt: Format

    // let info: String
    // let status: Int
    // let charset: String
    //

    enum Format: String, Decodable {
        case lrc
        case krc
    }
}
