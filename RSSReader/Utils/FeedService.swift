import Foundation
import Combine

/// 订阅源服务类（单例模式），负责获取和解析RSS订阅内容
class FeedService {
    // MARK: - 单例实例
    static let shared = FeedService()
    
    // MARK: - 初始化方法
    private init() {}  // 私有化初始化方法，确保单例模式
    
    // MARK: - 核心方法
    
    /// 从指定URL获取并解析文章内容
    /// - Parameters:
    ///   - feedURL: 订阅源的URL地址
    ///   - completion: 完成回调，返回Result类型（成功包含文章数组，失败包含Error）
    func fetchArticles(from feed: Feed, completion: @escaping (Result<[Article], Error>) -> Void) {
        // 创建URLSession数据任务
        URLSession.shared.dataTask(with: feed.url) { data, response, error in
            // 错误处理
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))  // 返回网络请求错误
                }
                return
            }
            
            // 数据有效性检查
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))  // 返回无效数据错误
                }
                return
            }
            
            // 使用RSS解析器处理数据
            let parser = RSSParser()
            do {
                
                //let feed = Feed(id: , title: "", url: feedURL)
                let (_, _, articles) = try parser.parse(data: data, feed: feed)
                DispatchQueue.main.async {
                    completion(.success(articles)) // 同时返回 feedTitle 和 articles
                            }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))  // 返回解析错误
                }
            }
        }.resume()  // 启动网络请求任务
    }
    
    // MARK: - 订阅导入导出功能
    
    /// 导出所有订阅为OPML格式文件，返回文件URL
    func exportFeeds(feeds: [Feed]) -> URL? {
        // 过滤有效订阅，确保导出内容不为空
        let validFeeds = feeds.filter { !$0.url.absoluteString.isEmpty }
        guard !validFeeds.isEmpty else {
            print("导出订阅失败：无有效订阅")
            return nil
        }
        let opmlString = generateOPML(from: validFeeds)
        guard let data = opmlString.data(using: .utf8) else {
            print("导出订阅失败：编码失败")
            return nil
        }
        // 如需自定义文件名（如用 feed 名字），可在此处修改 fileName 变量
        // 当前实现与 iOS 18 无关，写死为 feed.opml
        let fileName = "feed.opml"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
            // 先删除已存在的文件，避免写入失败
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try data.write(to: fileURL, options: .atomic)
            // 设置文件权限为可读写
            var fileAttributes = [FileAttributeKey: Any]()
            fileAttributes[.posixPermissions] = 0o644
            try FileManager.default.setAttributes(fileAttributes, ofItemAtPath: fileURL.path)
            return fileURL
        } catch {
            print("导出订阅失败: \(error)")
            return nil
        }
    }

    private func generateOPML(from feeds: [Feed]) -> String {
        var opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="1.0">
          <head>
            <title>RSSReader Subscriptions</title>
          </head>
          <body>
        """
        for feed in feeds {
            let title = feed.title.isEmpty ? feed.url.absoluteString : feed.title
            let xmlUrl = feed.url.absoluteString
            let htmlUrl = feed.link?.absoluteString
            if let htmlUrl = htmlUrl, !htmlUrl.isEmpty {
                opml += """
                  <outline type="rss" text="\(title)" xmlUrl="\(xmlUrl)" htmlUrl="\(htmlUrl)"/>
                """
            } else {
                opml += """
                  <outline type="rss" text="\(title)" xmlUrl="\(xmlUrl)"/>
                """
            }
        }
        opml += """
          </body>
        </opml>
        """
        return opml
    }
    
    /// 导入订阅，从JSON或OPML数据解析订阅数组
    func importFeeds(from data: Data, fileExtension: String) throws -> [Feed] {
        if fileExtension.lowercased() == "opml" {
            return try parseOPML(data: data)
        } else {
            let decoder = JSONDecoder()
            return try decoder.decode([Feed].self, from: data)
        }
    }

    private func parseOPML(data: Data) throws -> [Feed] {
        // 使用XMLParser解析OPML文件，提取订阅链接和标题
        let parser = OPMLParser(data: data)
        return try parser.parse()
    }
}
