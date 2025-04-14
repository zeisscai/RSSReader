//
//  Persistence.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架
import Foundation

/// 数据持久化管理类（单例模式）
class Persistence {
    // MARK: - 单例实例
    static let shared = Persistence()
    
    // MARK: - 文件路径
    private let feedsURL: URL    // 订阅源数据存储路径
    private let articlesURL: URL // 文章数据存储路径
    
    // MARK: - 初始化方法
    private init() {
        // 获取应用文档目录
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // 初始化订阅源和文章数据文件路径
        feedsURL = documents.appendingPathComponent("feeds.json")
        articlesURL = documents.appendingPathComponent("articles.json")
    }
    
    // MARK: - 订阅源数据操作
    
    /// 保存订阅源数据
    /// - Parameter feeds: 要保存的订阅源数组
    func saveFeeds(_ feeds: [Feed]) {
        do {
            // 编码为JSON数据
            let data = try JSONEncoder().encode(feeds)
            // 写入文件
            try data.write(to: feedsURL)
        } catch {
            print("保存订阅源失败: \(error)")
        }
    }
    
    /// 加载订阅源数据
    /// - Returns: 订阅源数组（失败时返回空数组）
    func loadFeeds() -> [Feed] {
        do {
            // 读取文件数据
            let data = try Data(contentsOf: feedsURL)
            // 解码JSON数据
            return try JSONDecoder().decode([Feed].self, from: data)
        } catch {
            print("加载订阅源失败: \(error)")
            return []
        }
    }
    
    // MARK: - 文章数据操作
    
    /// 保存文章数据
    /// - Parameter articles: 要保存的文章数组
    func saveArticles(_ articles: [Article]) {
        do {
            // 编码为JSON数据
            let data = try JSONEncoder().encode(articles)
            // 写入文件
            try data.write(to: articlesURL)
        } catch {
            print("保存文章失败: \(error)")
        }
    }
    
    /// 加载文章数据
    /// - Returns: 文章数组（失败时返回空数组）
    func loadArticles() -> [Article] {
        do {
            // 读取文件数据
            let data = try Data(contentsOf: articlesURL)
            // 解码JSON数据
            let articles = try JSONDecoder().decode([Article].self, from: data)
            return articles
        } catch {
            print("加载文章失败: \(error.localizedDescription)")
            return []  // 文件不存在或解析失败时返回空数组
        }
    }
}
