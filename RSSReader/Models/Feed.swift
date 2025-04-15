//
//  Feed.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

// 导入Foundation框架
import Foundation

/// 订阅源数据结构
struct Feed: Identifiable, Codable, Equatable {
    // 唯一标识符
    let id: UUID
    // 订阅源标题
    var title: String
    // 订阅源URL地址（订阅XML）
    var url: URL
    // 原文主页链接（如 https://xxx.com/）
    var link: URL?

    /// 初始化方法
    /// - Parameters:
    ///   - id: 唯一标识符（默认自动生成）
    ///   - title: 订阅源标题
    ///   - url: 订阅源URL地址
    ///   - link: 原文主页链接
    init(id: UUID = UUID(), title: String, url: URL, link: URL? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.link = link
    }
}
