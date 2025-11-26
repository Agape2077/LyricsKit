import Foundation
import Vapor
import LyricsService
import LyricsCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// 定义符合 Content 协议的输出结构，Vapor 会自动将其转为 JSON
struct LyricsOutput: Content {
    let id: String
    let title: String
    let artist: String
    let lyrics: String
    let source: String
}

@main
struct LyricsAPI {
    static func main() async throws {
        var env = try Environment.detect()
        // 初始化 Vapor 应用
        let app = Application(env)
        defer { app.shutdown() }

        // 1. 配置服务器：0.0.0.0:10492
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 10492

        // 2. 定义路由 GET /lyric
        app.get("lyrics") { req -> [LyricsOutput] in
            // 3. 获取参数
            let title = req.query[String.self, at: "title"] ?? ""
            let artist = req.query[String.self, at: "artist"] ?? ""
            
            // 参数校验
            if title.isEmpty && artist.isEmpty {
                return []
            }

            // limit 参数处理：默认 3，最大 10，最小 1
            let limitParam = req.query[Int.self, at: "limit"] ?? 3
            let limit = max(1, min(limitParam, 10))

            // 4. 构建搜索请求
            let searchReq = LyricsSearchRequest(
                searchTerm: .info(title: title, artist: artist),
                duration: 0, 
                limit: limit
            )

            // 定义数据源
            let providers: [any _LyricsProvider] = [
                LyricsProviders.Kugou(),
                LyricsProviders.NetEase(),
                LyricsProviders.QQMusic(),
                LyricsProviders.LRCLIB()
            ]

            // 5. 第一层并发：并行搜索多个源
            let allResults: [LyricsOutput] = await withTaskGroup(of: [LyricsOutput].self) { group in
                for provider in providers {
                    // 使用 helper 函数来解包 existential type "any _LyricsProvider"
                    group.addTask {
                        await processProvider(provider, request: searchReq)
                    }
                }

                // 收集所有结果
                var collected: [LyricsOutput] = []
                for await results in group {
                    collected.append(contentsOf: results)
                }
                return collected
            }
            
            return allResults
        }

        print("Server starting on http://0.0.0.0:10492")
        try app.run()
    }

    /// 处理单个 Provider 的完整流程：搜索 -> 并发获取详情 -> 格式化
    /// 使用泛型 P 来解包 any _LyricsProvider，让我们能访问具体的 Token 类型
    static func processProvider<P: _LyricsProvider>(_ provider: P, request: LyricsSearchRequest) async -> [LyricsOutput] {
        do {
            // 1. 搜索 (Search)
            // 这里是异步的，等待搜索结果返回
            let tokens = try await provider.search(for: request)
            
            // 截取需要的数量
            let limitedTokens = tokens.prefix(request.limit)
            
            // 2. 第二层并发：源内部并行获取歌词详情 (Concurrent Fetch)
            // 这解决了之前的性能瓶颈：不再是一个个排队下载，而是同时发起请求
            return await withTaskGroup(of: LyricsOutput?.self) { fetchGroup in
                for token in limitedTokens {
                    fetchGroup.addTask {
                        do {
                            // 异步获取单个歌词详情
                            let lyric = try await provider.fetch(with: token)
                            
                            // 手动补全 metadata (因为我们跳过了 provider.lyrics(for:) 的默认封装逻辑)
                            lyric.metadata.request = request
                            lyric.metadata.service = P.service
                            
                            let sourceName = P.service
                            
                            // 格式化歌词：添加来源头
                            let originalContent = lyric.description
                            let formattedContent = "[00:00:00] 来源：\(sourceName)\n\(originalContent)"
                            
                            return LyricsOutput(
                                id: lyric.metadata.serviceToken ?? "",
                                title: lyric.idTags[.title] ?? "",
                                artist: lyric.idTags[.artist] ?? "",
                                lyrics: formattedContent,
                                source: sourceName
                            )
                        } catch {
                            // 单个歌词下载失败（比如解密失败或网络超时），忽略它，不要影响其他结果
                            return nil
                        }
                    }
                }
                
                // 收集当前源成功获取到的所有歌词
                var providerResults: [LyricsOutput] = []
                for await result in fetchGroup {
                    if let res = result {
                        providerResults.append(res)
                    }
                }
                return providerResults
            }
        } catch {
            // 搜索阶段失败，返回空数组
            return []
        }
    }
}
