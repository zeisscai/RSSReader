//
//  ArticleDetailViewModel.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

class ArticleDetailViewModel: ObservableObject {
    @Published var article: Article

    init(article: Article) {
        self.article = article
        markAsReadIfNeeded()
    }

    private func markAsReadIfNeeded() {
        guard !article.isRead else { return }

        var updated = article
        updated.isRead = true

        var allArticles = Persistence.shared.loadArticles()
        if let index = allArticles.firstIndex(where: { $0.id == article.id }) {
            allArticles[index] = updated
            Persistence.shared.saveArticles(allArticles)
            article = updated
        }
    }

    func toggleFavorite() {
        article.isFavorite.toggle()

        var allArticles = Persistence.shared.loadArticles()
        if let index = allArticles.firstIndex(where: { $0.id == article.id }) {
            allArticles[index].isFavorite = article.isFavorite
            Persistence.shared.saveArticles(allArticles)
        }
    }
}
