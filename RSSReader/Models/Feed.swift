//
//  Feed.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

struct Feed: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var url: URL

    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
}
