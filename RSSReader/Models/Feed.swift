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
    // 订阅源URL地址
    var url: URL

    /// 初始化方法
    /// - Parameters:
    ///   - id: 唯一标识符（默认自动生成）
    ///   - title: 订阅源标题
    ///   - url: 订阅源URL地址
    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
}
