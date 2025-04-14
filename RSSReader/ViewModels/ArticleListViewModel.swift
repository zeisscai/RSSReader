//
//  ArticleListViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation
import Combine

class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var filter: ArticleFilter = .all

    private var allArticles: [Article] = []
    private var cancellables = Set<AnyCancellable>()

    enum ArticleFilter {
        case all, unread, favorites
    }

    init() {
        loadAllArticles()
        $filter
            .sink { [weak self] _ in self?.applyFilter() }
            .store(in: &cancellables)
    }

    //func loadArticles(for feed: Feed?) {
    //    if let feed = feed {
    //        allArticles = Persistence.shared
    //            .loadArticles()
    //            .filter { $0.feedID == feed.id }
    //    } else {
    //        allArticles = Persistence.shared.loadArticles()
    //    }
    //   applyFilter()
    //}
    
    func loadArticles(for feed: Feed) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("articles.json")

        // ✅ 如果文件不存在，直接返回空文章数组
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No cached articles file found, loading empty.")
            articles = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            articles = try JSONDecoder().decode([Article].self, from: data)
        } catch {
            print("Failed to load articles: \(error)")
            articles = [] // 加这一行确保不会崩溃
        }
    }

    
    private func applyFilter() {
        switch filter {
        case .all:
            articles = allArticles
        case .unread:
            articles = allArticles.filter { !$0.isRead }
        case .favorites:
            articles = allArticles.filter { $0.isFavorite }
        }
    }

    func markAsRead(_ article: Article) {
        updateArticle(article) { $0.isRead = true }
    }

    func toggleFavorite(_ article: Article) {
        updateArticle(article) { $0.isFavorite.toggle() }
    }

    private func updateArticle(_ article: Article, transform: (inout Article) -> Void) {
        guard let index = allArticles.firstIndex(where: { $0.id == article.id }) else { return }
        transform(&allArticles[index])
        var savedArticles = Persistence.shared.loadArticles()
        if let idx = savedArticles.firstIndex(where: { $0.id == article.id }) {
            transform(&savedArticles[idx])
            Persistence.shared.saveArticles(savedArticles)
        }
        applyFilter()
    }

    func refreshFromFeed(_ feed: Feed) {
        FeedService.shared.fetchArticles(from: feed.url) { result in
            switch result {
            case .success(let newArticles):
                var savedArticles = Persistence.shared.loadArticles()
                let existingIDs = Set(savedArticles.map { $0.link })

                let uniqueArticles = newArticles.filter { !existingIDs.contains($0.link) }

                savedArticles.append(contentsOf: uniqueArticles)
                Persistence.shared.saveArticles(savedArticles)
                self.loadArticles(for: feed)

            case .failure(let error):
                print("Fetch error: \(error)")
            }
        }
    }

    private func loadAllArticles() {
        allArticles = Persistence.shared.loadArticles()
        applyFilter()
    }
}
