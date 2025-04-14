//
//  ArticleListViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入基础框架
import Foundation
// 导入Combine框架用于响应式编程
import Combine

/// 文章列表视图模型，管理文章数据的加载、过滤和状态更新
class ArticleListViewModel: ObservableObject {
    // MARK: - 发布属性
    /// 当前显示的文章列表（根据过滤条件变化）
    @Published var articles: [Article] = []
    /// 当前激活的过滤条件
    @Published var filter: ArticleFilter = .all
    
    // MARK: - 私有属性
    /// 存储所有文章的原始数据（未过滤）
    private var allArticles: [Article] = []
    private var currentFeedArticles: [Article] = [] // 新增：当前订阅源文章
    /// Combine订阅容器
    private var cancellables = Set<AnyCancellable>()
    private var currentFeedID: UUID? // 新增：当前订阅源ID
    // MARK: - 过滤枚举
    /// 文章过滤条件枚举
    enum ArticleFilter {
        case all      // 显示全部文章
        case unread    // 仅显示未读文章
        case favorites // 仅显示收藏文章
    }
    
    // MARK: - 初始化方法
    init() {
        
        // 监听过滤条件变化
        $filter
            .sink { [weak self] _ in self?.applyFilter() }
            .store(in: &cancellables)
    }
    
    // MARK: - 数据加载方法
    /// 加载指定订阅源的文章（带本地缓存）
func loadArticles(for feed: Feed) {
        currentFeedID = feed.id
        let fileURL = getDocumentsDirectory().appendingPathComponent("articles.json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            resetArticles()
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            allArticles = try JSONDecoder().decode([Article].self, from: data)
            allArticles.prefix(5).forEach {
                print("\($0.id):\($0.feedID):\(feed.id) | 匹配结果: \($0.feedID == feed.id)")
                        }
            applyFilter()
        } catch {
            print("加载文章失败: \(error.localizedDescription)")
            resetArticles()
        }
    }
    
    /// 应用当前过滤条件
    private func applyFilter() {
        // 1. 按当前订阅源过滤
        currentFeedArticles = allArticles.filter {article in
            article.feedID == currentFeedID}
        //    guard let currentID = currentFeedID else { return false }
        //    return article.feedID == currentID
        //}
        
        // 2. 应用附加过滤条件
        switch filter {
        case .all:
            articles = currentFeedArticles
        case .unread:
            articles = currentFeedArticles.filter { !$0.isRead }
        case .favorites:
            articles = currentFeedArticles.filter { $0.isFavorite }
        }
    }
        
    private func resetArticles() {
        allArticles = []
        currentFeedArticles = []
        articles = []
    }
        
        
    
    // MARK: - 状态更新方法
    /// 标记文章为已读
    func markAsRead(_ article: Article) {
        updateArticle(article) { $0.isRead = true }
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ article: Article) {
        updateArticle(article) { $0.isFavorite.toggle() }
    }
    
    /// 通用文章更新方法
    private func updateArticle(_ article: Article, transform: (inout Article) -> Void) {
        // 更新内存数据
        guard let index = allArticles.firstIndex(where: { $0.id == article.id }) else { return }
        transform(&allArticles[index])
        
        // 更新持久化数据
        var savedArticles = Persistence.shared.loadArticles()
        if let idx = savedArticles.firstIndex(where: { $0.id == article.id }) {
            transform(&savedArticles[idx])
            Persistence.shared.saveArticles(savedArticles)
        }
        applyFilter()
    }
    
    // MARK: - 数据刷新方法
    /// 从订阅源刷新文章数据
    func refreshFromFeed(_ feed: Feed) {
        FeedService.shared.fetchArticles(from: feed) { result in
            switch result {
            case .success(let newArticles):
                var savedArticles = Persistence.shared.loadArticles()
                let existingIDs = Set(savedArticles.map { $0.link })
                _ = newArticles.filter { $0.feedID == feed.id }
                // 去重处理
                let uniqueArticles = newArticles.filter { !existingIDs.contains($0.link) }
                
                // 保存更新后的数据
                savedArticles.append(contentsOf: uniqueArticles)
                Persistence.shared.saveArticles(savedArticles)
                self.loadArticles(for: feed)
                
            case .failure(let error):
                print("文章刷新失败: \(error)")
                // 可在此处添加错误状态提示
            }
        }
    }
    

}

