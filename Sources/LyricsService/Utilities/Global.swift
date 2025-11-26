import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(FoundationXML)
import FoundationXML
#endif
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let sharedURLSession = URLSession(configuration: .ephemeral)
