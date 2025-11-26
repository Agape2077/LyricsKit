import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(FoundationXML)
import FoundationXML
#endif
struct KugouKrcHeaderFieldLanguage: Codable {
    let content: [Content]
    let version: Int

    struct Content: Codable {
        // TODO: resolve language/type code
        let language: Int
        let type: Int
        let lyricContent: [[String]]
    }
}
