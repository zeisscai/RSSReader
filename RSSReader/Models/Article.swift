//
//  Article.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var summary: String
    var content: String
    var date: Date
    //let date = parsedDate ?? Date() // fallback
    var link: URL
    var isRead: Bool
    var isFavorite: Bool
    var feedID: UUID

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        content: String,
        date: Date,
        link: URL,
        isRead: Bool = false,
        isFavorite: Bool = false,
        feedID: UUID
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.date = date
        self.link = link
        self.isRead = isRead
        self.isFavorite = isFavorite
        self.feedID = feedID
    }
}
