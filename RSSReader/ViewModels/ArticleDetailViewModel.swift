//
//  ArticleDetailViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架
import Foundation

/// 文章详情视图模型，管理文章的状态和持久化
class ArticleDetailViewModel: ObservableObject {
    // 使用@Published包装文章数据，当数据变化时自动通知视图更新
    @Published var article: Article

    // 初始化方法，接收文章对象
    init(article: Article) {
        self.article = article
        // 初始化时检查是否需要标记为已读
        markAsReadIfNeeded()
    }

    /// 私有方法：在首次加载时标记文章为已读（如果尚未读过）
    private func markAsReadIfNeeded() {
        // 如果已经是已读状态则直接返回
        guard !article.isRead else { return }

        // 创建文章的副本并更新为已读状态
        var updated = article
        updated.isRead = true

        // 从持久化存储加载所有文章
        var allArticles = Persistence.shared.loadArticles()
        // 查找当前文章在数组中的索引
        if let index = allArticles.firstIndex(where: { $0.id == article.id }) {
            // 更新数组中的文章状态
            allArticles[index] = updated
            // 保存更新后的数组
            Persistence.shared.saveArticles(allArticles)
            // 更新当前视图模型中的文章引用
            article = updated
        }
    }

    /// 切换文章的收藏状态
    func toggleFavorite() {
        // 反转当前的收藏状态
        article.isFavorite.toggle()

        // 从持久化存储加载所有文章
        var allArticles = Persistence.shared.loadArticles()
        // 查找当前文章在数组中的索引
        if let index = allArticles.firstIndex(where: { $0.id == article.id }) {
            // 更新数组中的文章收藏状态
            allArticles[index].isFavorite = article.isFavorite
            // 保存更新后的数组
            Persistence.shared.saveArticles(allArticles)
        }
    }
}
