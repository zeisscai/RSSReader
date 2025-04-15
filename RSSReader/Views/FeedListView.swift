//  FeedListView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import SwiftUI
import Combine

struct FeedListView: View {
    @EnvironmentObject var viewModel: FeedListViewModel
    @State private var showingAddFeed = false
    @State private var selectedFeedForEdit: Feed? = nil

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("你的内容")) {
                    ForEach(viewModel.feeds) { feed in
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
                                if let faviconURL = faviconURL {
                                    FaviconImageView(url: faviconURL, key: faviconKey)
                                } else {
                                    Image(systemName: "globe")
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.gray)
                                }
                                Text(feed.title)
                                Spacer()
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
                            .padding(.vertical, 10)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                selectedFeedForEdit = feed
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteFeed)
                }
            }
            .refreshable {
                viewModel.triggerRefresh()
                viewModel.refreshAllFaviconKeys()
            }
            .navigationTitle("订阅")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddFeed) {
                AddFeedView { urlString, customTitle in
                    if !urlString.isEmpty {
                        viewModel.addFeed(urlString: urlString, customTitle: customTitle)
                    }
                    showingAddFeed = false
                }
            }
                    .sheet(item: $selectedFeedForEdit) { feed in
                        EditFeedView(
                            feed: feed,
                            onSave: { newTitle, newURL in
                                // 直接调用viewModel的updateFeed方法
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
        NavigationStack {
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
                deleteSection
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
    // 恢复删除按钮，但去掉垃圾桶图标
    var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text("删除订阅")
            }
        }
    }
}

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
