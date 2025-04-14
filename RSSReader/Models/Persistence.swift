//
//  Persistence.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

class Persistence {
    static let shared = Persistence()

    private let feedsURL: URL
    private let articlesURL: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        feedsURL = documents.appendingPathComponent("feeds.json")
        articlesURL = documents.appendingPathComponent("articles.json")
    }

    // MARK: - Feeds

    func saveFeeds(_ feeds: [Feed]) {
        do {
            let data = try JSONEncoder().encode(feeds)
            try data.write(to: feedsURL)
        } catch {
            print("Failed to save feeds: \(error)")
        }
    }

    func loadFeeds() -> [Feed] {
        do {
            let data = try Data(contentsOf: feedsURL)
            return try JSONDecoder().decode([Feed].self, from: data)
        } catch {
            print("Failed to load feeds: \(error)")
            return []
        }
    }

    // MARK: - Articles

    func saveArticles(_ articles: [Article]) {
        do {
            let data = try JSONEncoder().encode(articles)
            try data.write(to: articlesURL)
        } catch {
            print("Failed to save articles: \(error)")
        }
    }

    func loadArticles() -> [Article] {
        do {
            let data = try Data(contentsOf: articlesURL)
            let articles = try JSONDecoder().decode([Article].self, from: data)
            return articles
            }
        catch {
                    print("Failed to load articles: \(error.localizedDescription)")
                    return []  // <-- 如果文件不存在，返回空数组即可
        }
    }
}
