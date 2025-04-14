//
//  FeedListViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation
@MainActor
class FeedListViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var articles: [Article] = []
    private let parser = RSSParser()
    
    func loadArticles(for feed: Feed) {
            FeedService.shared.fetchArticles(from: feed.url) { [weak self] result in
                switch result {
                case .success(let articles):
                    // 更新 articles 数组
                    self?.articles = articles
                case .failure(let error):
                    print("Error loading articles: \(error.localizedDescription)")
                }
            }
        }
    // 添加订阅方法（新增 title 参数，允许用户自定义）
    func addFeed(urlString: String, customTitle: String? = nil) {
        guard let url = URL(string: urlString) else { return }

        // 模拟网络请求
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let feedID = UUID()
                let (parsedTitle, _) = try parser.parse(data: data, feedID: feedID)

                let finalTitle = (customTitle?.isEmpty == false ? customTitle : parsedTitle) ?? urlString

                let newFeed = Feed(id: feedID, title: finalTitle, url: url)
                DispatchQueue.main.async {
                    self.feeds.append(newFeed)
                }
            } catch {
                print("添加订阅失败: \(error)")
            }
        }

    }

    // 删除订阅
    func deleteFeed(at offsets: IndexSet) {
        feeds.remove(atOffsets: offsets)
    }
}

