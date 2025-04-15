//  FeedListView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入SwiftUI框架，用于构建声明式UI
import SwiftUI
import Combine

// 定义订阅源列表视图，遵循View协议
struct FeedListView: View {
    // 使用@StateObject创建并持有视图模型的生命周期
    // 该属性在视图生命周期中只初始化一次
    @StateObject private var viewModel = FeedListViewModel()
    
    // 使用@State管理本地视图状态，控制添加订阅源弹窗的显示状态
    @State private var showingAddFeed = false

    // 编辑订阅弹窗相关状态
    @State private var selectedFeedForEdit: Feed? = nil

    // 定义视图内容
    var body: some View {
        // 创建导航视图容器
        NavigationView {
            // 使用列表展示订阅源
            List {
                // 遍历视图模型中的订阅源数据
                ForEach(viewModel.feeds) { feed in
                    // 预先拆分复杂表达式，减少 SwiftUI 嵌套类型推断压力
                    let faviconURL: URL? = {
                        if let link = feed.link, let host = link.host {
                            return URL(string: "https://\(host)/favicon.ico")
                        }
                        return nil
                    }()
                    let faviconKey = viewModel.faviconKey[feed.id, default: 0]
                    let unread = viewModel.unreadCount(for: feed)

                    NavigationLink(destination: ArticleListView(feed: feed)) {
                        HStack {
                            // 显示原文主页 favicon，支持强制刷新
                            if let faviconURL = faviconURL {
                                FaviconImageView(url: faviconURL, key: faviconKey)
                            } else {
                                // 没有主页链接时显示默认图标
                                Image(systemName: "globe")
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.gray)
                            }
                            // 显示订阅源标题
                            Text(feed.title)
                            Spacer()
                            // 显示未读数 badge
                            if unread > 0 {
                                let displayUnread = unread > 99 ? "99+" : "\(unread)"
                                Text(displayUnread)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 10) // 增大行间距
                    }
                    // 左滑只保留编辑按钮
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            selectedFeedForEdit = feed
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                // 添加滑动删除功能，绑定删除方法
                .onDelete(perform: deleteFeed)
            }
            // 下拉刷新
            .refreshable {
                await viewModel.refreshAllFeeds()
                viewModel.refreshAllFaviconKeys()
            }
            // 设置导航栏标题
            .navigationTitle("订阅源")
            // 添加工具栏按钮
            .toolbar {
                // 右侧工具栏按钮：添加订阅源
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 点击时切换弹窗显示状态
                        showingAddFeed = true
                    }) {
                        // 使用系统加号图标
                        Image(systemName: "plus")
                    }
                }
                
                // 左侧工具栏按钮：设置入口
                ToolbarItem(placement: .navigationBarLeading) {
                    // 导航链接到设置视图
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        // 使用系统齿轮图标
                        Image(systemName: "gear")
                    }
                }
            }
            // 添加订阅源弹窗
            .sheet(isPresented: $showingAddFeed) {
                AddFeedView { urlString, customTitle in
                    if !urlString.isEmpty {
                        viewModel.addFeed(
                            urlString: urlString,
                            customTitle: customTitle
                        )
                    }
                    showingAddFeed = false
                }
            }
            // 编辑订阅弹窗
            .sheet(item: $selectedFeedForEdit) { feed in
                EditFeedView(
                    feed: feed,
                    onSave: { newTitle, newURL in
                        viewModel.updateFeed(feed: feed, newTitle: newTitle, newURL: newURL)
                        selectedFeedForEdit = nil
                    },
                    onDelete: {
                        if let idx = viewModel.feeds.firstIndex(where: { $0.id == feed.id }) {
                            withAnimation {
                                viewModel.deleteFeed(at: IndexSet(integer: idx))
                            }
                        }
                        selectedFeedForEdit = nil
                    }
                )
            }
        }
    }

    // MARK: - 数据操作方法
    /// 删除指定位置的订阅源
    /// - Parameter offsets: 包含要删除索引的集合
    private func deleteFeed(at offsets: IndexSet) {
        withAnimation {
            viewModel.deleteFeed(at: offsets)
        }
    }
}

// 简单编辑订阅弹窗
struct EditFeedView: View {
    let feed: Feed
    let onSave: (String, String) -> Void
    let onDelete: () -> Void
    @State private var title: String
    @State private var urlString: String

    init(feed: Feed, onSave: @escaping (String, String) -> Void, onDelete: @escaping () -> Void) {
        self.feed = feed
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: feed.title)
        _urlString = State(initialValue: feed.url.absoluteString)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("订阅标题")) {
                    TextField("标题", text: $title)
                }
                Section(header: Text("订阅链接")) {
                    TextField("链接", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("删除订阅", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("编辑订阅")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(title, urlString)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onSave(feed.title, feed.url.absoluteString)
                    }
                }
            }
        }
    }
}

// FeedListViewModel 扩展：更新订阅标题和链接
extension FeedListViewModel {
    func updateFeed(feed: Feed, newTitle: String, newURL: String) {
        guard let idx = feeds.firstIndex(where: { $0.id == feed.id }) else { return }
        feeds[idx].title = newTitle
        if let url = URL(string: newURL), url.scheme?.hasPrefix("http") == true {
            feeds[idx].url = url
        }
        // 如有持久化需求，可同步更新本地存储
    }
}

// MARK: - favicon 内存缓存视图
struct FaviconImageView: View {
    let url: URL
    let key: Int

    @State private var image: Image? = nil
    @State private var cancellable: AnyCancellable?

    static private let cache = NSCache<NSURL, UIImage>()

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .frame(width: 20, height: 20)
                    .cornerRadius(4)
            } else {
                Image(systemName: "globe")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray)
                    .onAppear {
                        loadFavicon()
                    }
            }
        }
        .id(key)
    }

    private func loadFavicon() {
        if let cached = Self.cache.object(forKey: url as NSURL) {
            self.image = Image(uiImage: cached)
            return
        }
        cancellable?.cancel()
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { uiImage in
                if let uiImage = uiImage {
                    Self.cache.setObject(uiImage, forKey: url as NSURL)
                    self.image = Image(uiImage: uiImage)
                }
            }
    }
}
