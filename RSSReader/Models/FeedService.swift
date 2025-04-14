//
//  FeedService.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

// 导入Foundation框架
import Foundation

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
    func fetchArticles(from feedURL: URL, completion: @escaping (Result<[Article], Error>) -> Void) {
        // 创建URLSession数据任务
        URLSession.shared.dataTask(with: feedURL) { data, response, error in
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
                let (_, articles) = try parser.parse(data: data, feedID: UUID())
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
}
