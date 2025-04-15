//
//  FeedListViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架，提供基础网络和数据处理功能
import Foundation

// 使用@MainActor确保所有UI更新都在主线程执行
// 遵循ObservableObject协议，用于在SwiftUI中实现数据绑定
@MainActor
class FeedListViewModel: ObservableObject {
    // 使用@Published属性包装器，当数据变化时自动通知视图更新
    @Published var feeds: [Feed] = []       // 存储订阅源列表数据
    @Published var articles: [Article] = []  // 存储当前选中的文章列表
    private let parser = RSSParser()        // RSS解析器实例

    init() {
        NotificationCenter.default.addObserver(
            forName: .articleStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.reloadArticlesFromDisk()
            }
        }
    }

    /// 重新加载本地所有文章（用于未读数同步）
    func reloadArticlesFromDisk() {
        let all = Persistence.shared.loadArticles()
        self.articles = all
    }
    
    // MARK: - 数据加载方法
    
    /// 加载指定订阅源的文章
    /// - Parameter feed: 需要加载文章的订阅源对象
    func loadArticles(for feed: Feed) {
        FeedService.shared.fetchArticles(from: feed) { [weak self] result in
            switch result {
            case .success(let articles):
                // 使用主线程更新UI数据（虽然已在@MainActor中，但显式声明确保安全）
                DispatchQueue.main.async {
                    self?.articles = articles
                }
            case .failure(let error):
                // 错误处理：打印日志（实际项目可替换为错误提示）
                print("文章加载失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 订阅管理方法
    
    /// 添加新订阅源（支持自定义标题）
    /// - Parameters:
    ///   - urlString: 订阅源URL字符串
    ///   - customTitle: 用户自定义标题（可选）
    func addFeed(urlString: String, customTitle: String? = nil) {
        // 验证URL有效性
        guard let url = URL(string: urlString) else {
            print("无效的URL格式")
            return
        }

        // 使用异步任务处理网络请求
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // 发起网络请求获取RSS数据
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // 生成唯一标识符用于本地存储
                let feedID = UUID()
                // 创建新的订阅源对象
                let feed = Feed(id: feedID, title: "", url: url)
                // 解析RSS数据，获取标题和主页链接
                let (parsedTitle, parsedLink, _) = try parser.parse(data: data, feed: feed)
                print("[添加订阅] 初始ID: \(feedID)")
                // 确定最终显示标题：优先使用用户输入 > 解析结果 > 原始URL
                let finalTitle = (customTitle?.isEmpty == false ? customTitle : parsedTitle) ?? urlString
                // 主页链接
                let homepageURL = parsedLink.flatMap { URL(string: $0) }
                let newFeed = Feed(id: feedID, title: finalTitle, url: url, link: homepageURL)
                
                // 主线程更新数据源
                DispatchQueue.main.async {
                    self.feeds.append(newFeed)
                }
            } catch {
                // 统一错误处理
                print("订阅添加失败: \(error)")
                // 实际项目中可在此处添加错误提示状态
            }
        }
    }

    /// 删除指定位置的订阅源
    /// - Parameter offsets: 包含要删除索引的集合
    func deleteFeed(at offsets: IndexSet) {
        // 直接操作数据源实现删除
        feeds.remove(atOffsets: offsets)
    }

    /// 刷新所有订阅源，拉取所有订阅源的最新文章
    func refreshAllFeeds() async {
        // 先加载本地所有文章，便于合并已读/收藏状态
        let localArticles = Persistence.shared.loadArticles()
        var allArticles: [Article] = []
        for feed in feeds {
            do {
                let (data, _) = try await URLSession.shared.data(from: feed.url)
                let (_, _, newArticles) = try parser.parse(data: data, feed: feed)
                // 合并本地已读/收藏状态
                let merged = newArticles.map { new in
                    if let local = localArticles.first(where: { $0.link == new.link }) {
                        var copy = new
                        copy.isRead = local.isRead
                        copy.isFavorite = local.isFavorite
                        return copy
                    }
                    return new
                }
                allArticles.append(contentsOf: merged)
            } catch {
                print("刷新订阅源失败: \(feed.title) \(error)")
            }
        }
        // 主线程更新
        await MainActor.run {
            self.articles = allArticles
            // 持久化保存所有文章，供 ArticleListViewModel 读取
            Persistence.shared.saveArticles(allArticles)
        }
    }

    /// 获取某个订阅源的未读数
    func unreadCount(for feed: Feed) -> Int {
        articles.filter { $0.feedID == feed.id && !$0.isRead }.count
    }

    // MARK: - favicon 刷新支持
    @Published var faviconKey: [UUID: Int] = [:]

    /// 刷新所有 favicon key，强制 AsyncImage 重新加载
    func refreshAllFaviconKeys() {
        for feed in feeds {
            faviconKey[feed.id, default: 0] += 1
        }
    }
}
