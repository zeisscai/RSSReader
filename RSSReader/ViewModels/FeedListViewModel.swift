//
//  FeedListViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架，提供基础网络和数据处理功能
import Foundation
import Combine

// 为Array添加分块扩展
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// 使用@MainActor确保所有UI更新都在主线程执行
// 遵循ObservableObject协议，用于在SwiftUI中实现数据绑定
@MainActor
class FeedListViewModel: ObservableObject {
    // 使用@Published属性包装器，当数据变化时自动通知视图更新
    @Published var feeds: [Feed] = []       // 存储订阅源列表数据
    @Published var articles: [Article] = []  // 存储当前选中的文章列表
    private let parser = RSSParser()        // RSS解析器实例

    private let refreshSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 初始化时加载已有订阅源
        loadInitialData()
        
        // 设置文章状态变化的通知观察者
        setupObservers()
    }
    
    private func loadInitialData() {
        Task { @MainActor in
            do {
                let loadedFeeds = Persistence.shared.loadFeeds()
                self.feeds = loadedFeeds
                print("成功加载\(loadedFeeds.count)个订阅源")
                
                // 初始加载文章数据
                if !loadedFeeds.isEmpty {
                    self.reloadArticlesFromDisk()
                }
                // 确保faviconKey初始化
                self.refreshAllFaviconKeys()
            } catch {
                print("初始化加载失败: \(error)")
                self.feeds = []
            }
        }
    }
    
    private func setupObservers() {
        // 文章状态变化观察者
        NotificationCenter.default.addObserver(
            forName: .articleStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleArticleStatusChange()
        }
        
        // 刷新逻辑
        refreshSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .flatMap { _ in
                Future<Void, Never> { [weak self] promise in
                    Task {
                        await self?.performRefresh()
                        promise(.success(()))
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAllFaviconKeys()
            }
            .store(in: &cancellables)
    }
    
    private func handleArticleStatusChange() {
        Task { @MainActor in
            self.reloadArticlesFromDisk()
            self.updateUnreadCountCache()
        }
    }

    /// 重新加载本地所有文章（用于未读数同步）
    func reloadArticlesFromDisk() {
        let all = Persistence.shared.loadArticles()
        self.articles = all
        self.updateUnreadCountCache()
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
    ///   - completion: 操作完成回调，参数为 Result<Void, Error>
    func addFeed(urlString: String, customTitle: String? = nil, completion: ((Result<Void, Error>) -> Void)? = nil) {
        // 验证URL有效性
        guard let url = URL(string: urlString) else {
            completion?(.failure(NSError(domain: "FeedListViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL格式"])))
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
                await MainActor.run {
                    self.feeds.append(newFeed)
                    Persistence.shared.saveFeeds(self.feeds)
                    self.refreshAllFaviconKeys()
                }
                completion?(.success(()))
            } catch {
                print("订阅添加失败: \(error)")
                completion?(.failure(error))
            }
        }
    }

    /// 删除指定位置的订阅源
    /// - Parameter offsets: 包含要删除索引的集合
    func deleteFeed(at offsets: IndexSet) {
        // 直接操作数据源实现删除
        feeds.remove(atOffsets: offsets)
    }


    func triggerRefresh() {
        refreshSubject.send(())
    }

    private func performRefresh() async {
        // 先加载本地所有文章，便于合并已读/收藏状态
        let localArticles = Persistence.shared.loadArticles()
        var allArticles: [Article] = []
        
        // 串行处理每个订阅源
        for feed in feeds {
            do {
                let (data, _) = try await URLSession.shared.data(from: feed.url)
                let (_, _, newArticles) = try self.parser.parse(data: data, feed: feed)
                
                // 合并本地已读/收藏状态
                let mergedArticles = newArticles.map { new in
                    if let local = localArticles.first(where: { $0.link == new.link }) {
                        var copy = new
                        copy.isRead = local.isRead
                        copy.isFavorite = local.isFavorite
                        return copy
                    }
                    return new
                }
                
                allArticles.append(contentsOf: mergedArticles)
                
                // 每个订阅源处理完后立即更新UI
                await MainActor.run {
                    self.articles = allArticles
                    Persistence.shared.saveArticles(allArticles)
                    self.updateUnreadCountCache()
                }
                
            } catch {
                print("刷新订阅源失败: \(feed.title) \(error)")
            }
        }
    }

    // 未读数缓存
    private var unreadCountCache: [UUID: Int] = [:]
    
    /// 获取某个订阅源的未读数（使用缓存优化性能）
    func unreadCount(for feed: Feed) -> Int {
        if let cached = unreadCountCache[feed.id] {
            return cached
        }
        let count = articles.filter { $0.feedID == feed.id && !$0.isRead }.count
        unreadCountCache[feed.id] = count
        return count
    }
    
    /// 更新未读数缓存（在文章状态变化时调用）
    private func updateUnreadCountCache() {
        unreadCountCache.removeAll()
        for feed in feeds {
            unreadCountCache[feed.id] = articles.filter { $0.feedID == feed.id && !$0.isRead }.count
        }
    }

    // MARK: - favicon 刷新支持
    @Published var faviconKey: [UUID: Int] = [:]

    /// 刷新所有 favicon key，强制 AsyncImage 重新加载
    func refreshAllFaviconKeys() {
        for feed in feeds {
            faviconKey[feed.id, default: 0] += 1
        }
    }

    /// 更新订阅源信息（标题和链接）
    func updateFeed(feed: Feed, newTitle: String, newURL: String) {
        guard let url = URL(string: newURL) else { return }
        if let index = feeds.firstIndex(where: { $0.id == feed.id }) {
            feeds[index].title = newTitle
            feeds[index].url = url
        }
    }
}
