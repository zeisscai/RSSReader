//
//  Article.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架
import Foundation

/// 文章数据结构
struct Article: Identifiable, Codable, Equatable {
    // 文章唯一标识符
    let id: UUID
    // 文章标题
    var title: String
    // 文章摘要
    var summary: String
    // 文章完整内容
    var content: String
    // 文章发布日期
    var date: Date
    // 文章原始链接
    var link: URL
    // 是否已读标记
    var isRead: Bool
    // 是否收藏标记
    var isFavorite: Bool
    // 所属订阅源的ID
    var feedID: UUID

    /// 初始化方法
    /// - Parameters:
    ///   - id: 文章ID（默认自动生成）
    ///   - title: 文章标题
    ///   - summary: 文章摘要
    ///   - content: 文章内容
    ///   - date: 发布日期
    ///   - link: 原文链接
    ///   - isRead: 是否已读（默认false）
    ///   - isFavorite: 是否收藏（默认false）
    ///   - feedID: 所属订阅源ID
    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        content: String,
        date: Date,
        link: URL,
        isRead: Bool = false,
        isFavorite: Bool = false,
        feedID: UUID
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.date = date
        self.link = link
        self.isRead = isRead
        self.isFavorite = isFavorite
        self.feedID = feedID
    }
}
